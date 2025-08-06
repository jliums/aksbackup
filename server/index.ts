import express from 'express';
import cors from 'cors';
import { createClient } from 'redis';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// Serve static files from the public directory (built frontend)
app.use(express.static(path.join(__dirname, '..', 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    redisConnected: redisClient ? true : false
  });
});

let redisClient: any = null;
let pingInterval: NodeJS.Timeout | null = null;

// Redis connection endpoint
app.post('/api/redis/connect', async (req, res) => {
  try {
    const { host, port, password, database } = req.body;

    if (redisClient) {
      await redisClient.quit();
    }

    redisClient = createClient({
      socket: {
        host: host || 'localhost',
        port: port || 6379,
      },
      password: password || undefined,
      database: database || 0,
    });

    redisClient.on('error', (err: any) => {
      console.error('Redis Client Error', err);
    });

    await redisClient.connect();
    res.json({ success: true, message: 'Connected to Redis successfully' });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Test Redis connection
app.get('/api/redis/ping', async (req, res) => {
  try {
    if (!redisClient) {
      return res.status(400).json({ success: false, message: 'Not connected to Redis' });
    }

    const pong = await redisClient.ping();
    res.json({ success: true, message: pong });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Execute Redis command
app.post('/api/redis/command', async (req, res) => {
  try {
    if (!redisClient) {
      return res.status(400).json({ success: false, message: 'Not connected to Redis' });
    }

    const { command, args } = req.body;
    const result = await redisClient.sendCommand([command, ...(args || [])]);
    res.json({ success: true, result });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Start ping timer
app.post('/api/redis/start-ping', async (req, res) => {
  try {
    const { interval } = req.body; // interval in seconds

    if (pingInterval) {
      clearInterval(pingInterval);
    }

    pingInterval = setInterval(async () => {
      if (redisClient) {
        try {
          const timestamp = new Date().toISOString();
          await redisClient.lPush(
            'ping_entries',
            JSON.stringify({
              timestamp,
              message: 'ping',
              id: Date.now(),
            }),
          );
        } catch (error) {
          console.error('Ping error:', error);
        }
      }
    }, interval * 1000);

    res.json({ success: true, message: `Ping timer started with ${interval}s interval` });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Stop ping timer
app.post('/api/redis/stop-ping', (req, res) => {
  if (pingInterval) {
    clearInterval(pingInterval);
    pingInterval = null;
    res.json({ success: true, message: 'Ping timer stopped' });
  } else {
    res.json({ success: false, message: 'No ping timer running' });
  }
});

// Get ping entries
app.get('/api/redis/ping-entries', async (req, res) => {
  try {
    if (!redisClient) {
      return res.status(400).json({ success: false, message: 'Not connected to Redis' });
    }

    const entries = await redisClient.lRange('ping_entries', 0, -1);
    const parsedEntries = entries.map((entry: string) => JSON.parse(entry)).reverse();
    res.json({ success: true, entries: parsedEntries });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Clear ping entries
app.delete('/api/redis/ping-entries', async (req, res) => {
  try {
    if (!redisClient) {
      return res.status(400).json({ success: false, message: 'Not connected to Redis' });
    }

    await redisClient.del('ping_entries');
    res.json({ success: true, message: 'Ping entries cleared' });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ success: false, message: errorMessage });
  }
});

// Catch-all handler for SPA routing (must be last)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Frontend available at http://localhost:${PORT}`);
});
