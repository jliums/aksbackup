import { defineStore } from 'pinia';
import { ref } from 'vue';
import axios from 'axios';
import type { RedisConnection, PingEntry, ApiResponse, RedisCommand } from '../types';

const API_BASE = 'http://localhost:3001/api';

export const useRedisStore = defineStore('redis', () => {
  // State
  const isConnected = ref(false);
  const connectionSettings = ref<RedisConnection>({
    host: 'localhost',
    port: 6379,
    password: '',
    database: 0,
  });
  const pingInterval = ref(10); // seconds
  const isPingActive = ref(false);
  const pingEntries = ref<PingEntry[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  // Actions
  const connectToRedis = async (): Promise<boolean> => {
    try {
      isLoading.value = true;
      error.value = null;

      const response = await axios.post<ApiResponse>(
        `${API_BASE}/redis/connect`,
        connectionSettings.value,
      );

      if (response.data.success) {
        isConnected.value = true;
        return true;
      } else {
        error.value = response.data.message || 'Connection failed';
        return false;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Connection failed';
      isConnected.value = false;
      return false;
    } finally {
      isLoading.value = false;
    }
  };

  const testConnection = async (): Promise<boolean> => {
    try {
      const response = await axios.get<ApiResponse>(`${API_BASE}/redis/ping`);
      return response.data.success;
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Ping failed';
      return false;
    }
  };

  const executeCommand = async (command: RedisCommand): Promise<unknown> => {
    try {
      error.value = null;
      const response = await axios.post<ApiResponse>(`${API_BASE}/redis/command`, command);

      if (response.data.success) {
        return response.data.result;
      } else {
        error.value = response.data.message || 'Command failed';
        throw new Error(error.value);
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Command failed';
      throw err;
    }
  };

  const startPingTimer = async (): Promise<boolean> => {
    try {
      const response = await axios.post<ApiResponse>(`${API_BASE}/redis/start-ping`, {
        interval: pingInterval.value,
      });

      if (response.data.success) {
        isPingActive.value = true;
        return true;
      } else {
        error.value = response.data.message || 'Failed to start ping timer';
        return false;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to start ping timer';
      return false;
    }
  };

  const stopPingTimer = async (): Promise<boolean> => {
    try {
      const response = await axios.post<ApiResponse>(`${API_BASE}/redis/stop-ping`);

      if (response.data.success) {
        isPingActive.value = false;
        return true;
      } else {
        error.value = response.data.message || 'Failed to stop ping timer';
        return false;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to stop ping timer';
      return false;
    }
  };

  const fetchPingEntries = async (): Promise<void> => {
    try {
      const response = await axios.get<ApiResponse<PingEntry[]>>(`${API_BASE}/redis/ping-entries`);

      if (response.data.success && response.data.entries) {
        pingEntries.value = response.data.entries;
      } else {
        error.value = response.data.message || 'Failed to fetch ping entries';
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch ping entries';
    }
  };

  const clearPingEntries = async (): Promise<boolean> => {
    try {
      const response = await axios.delete<ApiResponse>(`${API_BASE}/redis/ping-entries`);

      if (response.data.success) {
        pingEntries.value = [];
        return true;
      } else {
        error.value = response.data.message || 'Failed to clear ping entries';
        return false;
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to clear ping entries';
      return false;
    }
  };

  const updateConnectionSettings = (settings: Partial<RedisConnection>): void => {
    connectionSettings.value = { ...connectionSettings.value, ...settings };
  };

  const updatePingInterval = (interval: number): void => {
    pingInterval.value = interval;
  };

  const clearError = (): void => {
    error.value = null;
  };

  return {
    // State
    isConnected,
    connectionSettings,
    pingInterval,
    isPingActive,
    pingEntries,
    isLoading,
    error,
    // Actions
    connectToRedis,
    testConnection,
    executeCommand,
    startPingTimer,
    stopPingTimer,
    fetchPingEntries,
    clearPingEntries,
    updateConnectionSettings,
    updatePingInterval,
    clearError,
  };
});
