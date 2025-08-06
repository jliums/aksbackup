export interface RedisConnection {
  host: string;
  port: number;
  password?: string;
  database: number;
}

export interface PingEntry {
  id: number;
  timestamp: string;
  message: string;
}

export interface RedisCommand {
  command: string;
  args?: string[];
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  result?: T;
  entries?: T;
}

export interface AppSettings {
  redisConnection: RedisConnection;
  pingInterval: number; // in seconds
  isPingActive: boolean;
}
