<template>
  <q-page padding>
    <div class="q-pa-md">
      <h4 class="text-h4 q-mb-md">Redis Settings</h4>

      <!-- Connection Settings -->
      <q-card class="q-mb-lg">
        <q-card-section>
          <div class="text-h6 q-mb-md">Redis Connection</div>

          <div class="row q-gutter-md">
            <div class="col-12 col-md-5">
              <q-input v-model="localSettings.host" label="Host" outlined dense :disable="redisStore.isConnected" />
            </div>

            <div class="col-12 col-md-3">
              <q-input v-model.number="localSettings.port" label="Port" type="number" outlined dense
                :disable="redisStore.isConnected" />
            </div>

            <div class="col-12 col-md-3">
              <q-input v-model.number="localSettings.database" label="Database" type="number" outlined dense
                :disable="redisStore.isConnected" />
            </div>
          </div>

          <div class="row q-gutter-md q-mt-sm">
            <div class="col-12 col-md-6">
              <q-input v-model="localSettings.password" label="Password (optional)" type="password" outlined dense
                :disable="redisStore.isConnected" />
            </div>
          </div>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn v-if="!redisStore.isConnected" color="primary" label="Connect" :loading="redisStore.isLoading"
            @click="handleConnect" />
          <q-btn v-if="redisStore.isConnected" color="secondary" label="Test Connection"
            @click="handleTestConnection" />
          <q-btn v-if="redisStore.isConnected" color="negative" label="Disconnect" @click="handleDisconnect" />

        </q-card-actions>
      </q-card>

      <!-- Ping Timer Settings -->
      <q-card class="q-mb-lg">
        <q-card-section>
          <div class="text-h6 q-mb-md">Ping Timer Settings</div>

          <div class="row q-gutter-md items-center">
            <div class="col-12 col-md-4">
              <q-input v-model.number="localPingInterval" label="Ping Interval (seconds)" type="number" min="1" outlined
                dense :disable="redisStore.isPingActive" />
            </div>

            <div class="col-auto">
              <q-btn v-if="!redisStore.isPingActive" color="positive" label="Start Ping Timer"
                :disable="!redisStore.isConnected" @click="handleStartPing" />
              <q-btn v-else color="negative" label="Stop Ping Timer" @click="handleStopPing" />
            </div>
          </div>

          <div class="q-mt-md">
            <q-banner v-if="redisStore.isPingActive" class="bg-positive text-white" rounded>
              <template v-slot:avatar>
                <q-icon name="timer" />
              </template>
              Ping timer is active with {{ redisStore.pingInterval }}s interval
            </q-banner>
          </div>
        </q-card-section>
      </q-card>

      <!-- Connection Status -->
      <q-card>
        <q-card-section>
          <div class="text-h6 q-mb-md">Connection Status</div>

          <div class="row q-gutter-md items-center">
            <div class="col-auto">
              <q-icon :name="redisStore.isConnected ? 'check_circle' : 'cancel'"
                :color="redisStore.isConnected ? 'positive' : 'negative'" size="md" />
            </div>
            <div class="col">
              <div class="text-body1">
                {{ redisStore.isConnected ? 'Connected to Redis' : 'Not connected' }}
              </div>
              <div v-if="redisStore.isConnected" class="text-caption text-grey-6">
                {{ redisStore.connectionSettings.host }}:{{ redisStore.connectionSettings.port }}/{{
                  redisStore.connectionSettings.database }}
              </div>
            </div>
          </div>
        </q-card-section>
      </q-card>

      <!-- Error Display -->
      <q-banner v-if="redisStore.error" class="bg-negative text-white q-mt-md" rounded>
        <template v-slot:avatar>
          <q-icon name="error" />
        </template>
        {{ redisStore.error }}
        <template v-slot:action>
          <q-btn flat color="white" label="Dismiss" @click="redisStore.clearError" />
        </template>
      </q-banner>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useQuasar } from 'quasar';
import { useRedisStore } from '../stores/redis';
import type { RedisConnection } from '../types';

const $q = useQuasar();
const redisStore = useRedisStore();

const localSettings = ref<RedisConnection>({
  host: 'localhost',
  port: 6379,
  password: '',
  database: 0,
});

const localPingInterval = ref(10);

onMounted(() => {
  // Initialize local settings with store values
  localSettings.value = { ...redisStore.connectionSettings };
  localPingInterval.value = redisStore.pingInterval;
});

const handleConnect = async () => {
  redisStore.updateConnectionSettings(localSettings.value);
  redisStore.updatePingInterval(localPingInterval.value);

  const success = await redisStore.connectToRedis();

  if (success) {
    $q.notify({
      type: 'positive',
      message: 'Successfully connected to Redis!',
      position: 'top',
    });
  } else {
    $q.notify({
      type: 'negative',
      message: redisStore.error || 'Failed to connect to Redis',
      position: 'top',
    });
  }
};

const handleTestConnection = async () => {
  const success = await redisStore.testConnection();

  $q.notify({
    type: success ? 'positive' : 'negative',
    message: success ? 'Connection test successful!' : 'Connection test failed',
    position: 'top',
  });
};

const handleDisconnect = () => {
  // In a real app, you might want to add a disconnect endpoint
  redisStore.isConnected = false;
  redisStore.isPingActive = false;

  $q.notify({
    type: 'info',
    message: 'Disconnected from Redis',
    position: 'top',
  });
};

const handleStartPing = async () => {
  redisStore.updatePingInterval(localPingInterval.value);

  const success = await redisStore.startPingTimer();

  if (success) {
    $q.notify({
      type: 'positive',
      message: `Ping timer started with ${localPingInterval.value}s interval`,
      position: 'top',
    });
  } else {
    $q.notify({
      type: 'negative',
      message: redisStore.error || 'Failed to start ping timer',
      position: 'top',
    });
  }
};

const handleStopPing = async () => {
  const success = await redisStore.stopPingTimer();

  if (success) {
    $q.notify({
      type: 'info',
      message: 'Ping timer stopped',
      position: 'top',
    });
  } else {
    $q.notify({
      type: 'negative',
      message: redisStore.error || 'Failed to stop ping timer',
      position: 'top',
    });
  }
};
</script>
