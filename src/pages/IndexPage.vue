<template>
  <q-page padding>
    <div class="q-pa-md">
      <h4 class="text-h4 q-mb-md">Redis Dashboard</h4>

      <!-- Connection Status Banner -->
      <q-banner v-if="!redisStore.isConnected" class="bg-warning text-dark q-mb-md" rounded>
        <template v-slot:avatar>
          <q-icon name="warning" />
        </template>
        Not connected to Redis. Please configure connection in Settings.
        <template v-slot:action>
          <q-btn flat color="dark" label="Go to Settings" to="/settings" />
        </template>
      </q-banner>

      <!-- Redis Command Interface -->
      <q-card v-if="redisStore.isConnected" class="q-mb-lg">
        <q-card-section>
          <div class="text-h6 q-mb-md">Redis Command Interface</div>

          <div class="row q-gutter-md">
            <div class="col-12 col-md-4">
              <q-input v-model="commandInput.command" label="Command" outlined dense
                placeholder="e.g., GET, SET, KEYS" />
            </div>

            <div class="col-12 col-md-6">
              <q-input v-model="commandInput.argsString" label="Arguments (space-separated)" outlined dense
                placeholder="e.g., mykey myvalue" />
            </div>

            <div class="col-12 col-md-2">
              <q-btn color="primary" label="Execute" class="full-width" :disable="!commandInput.command"
                @click="executeCommand" />
            </div>
          </div>

          <!-- Command Result -->
          <div v-if="commandResult !== null" class="q-mt-md">
            <q-separator class="q-mb-md" />
            <div class="text-subtitle2 q-mb-sm">Result:</div>
            <q-card flat bordered>
              <q-card-section>
                <pre class="text-body2">{{ formatResult(commandResult) }}</pre>
              </q-card-section>
            </q-card>
          </div>
        </q-card-section>
      </q-card>

      <!-- Ping Entries Table -->
      <q-card v-if="redisStore.isConnected">
        <q-card-section>
          <div class="row items-center justify-between q-mb-md">
            <div class="text-h6">Ping Entries</div>
            <div class="q-gutter-sm">
              <q-btn color="primary" label="Refresh" icon="refresh" @click="refreshPingEntries" />
              <q-btn color="negative" label="Clear All" icon="clear" @click="clearAllEntries" />
            </div>
          </div>

          <q-table :rows="redisStore.pingEntries" :columns="pingColumns" row-key="id" :pagination="{ rowsPerPage: 10 }"
            flat bordered>
            <template v-slot:body-cell-timestamp="props">
              <q-td :props="props">
                {{ formatTimestamp(props.value) }}
              </q-td>
            </template>

            <template v-slot:no-data>
              <div class="full-width row flex-center text-grey-6 q-gutter-sm">
                <q-icon size="2em" name="info" />
                <span>No ping entries found</span>
              </div>
            </template>
          </q-table>
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
import { ref, onMounted, onUnmounted } from 'vue';
import { useQuasar } from 'quasar';
import { useRedisStore } from '../stores/redis';

const $q = useQuasar();
const redisStore = useRedisStore();

const commandInput = ref({
  command: '',
  argsString: '',
});

const commandResult = ref<unknown>(null);

const pingColumns = [
  {
    name: 'id',
    label: 'ID',
    field: 'id',
    align: 'left' as const,
    sortable: true,
  },
  {
    name: 'timestamp',
    label: 'Timestamp',
    field: 'timestamp',
    align: 'left' as const,
    sortable: true,
  },
  {
    name: 'message',
    label: 'Message',
    field: 'message',
    align: 'left' as const,
  },
];

let refreshInterval: NodeJS.Timeout | null = null;

onMounted(() => {
  if (redisStore.isConnected) {
    void refreshPingEntries();
    // Auto-refresh ping entries every 5 seconds
    refreshInterval = setInterval(() => void refreshPingEntries(), 5000);
  }
});

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval);
  }
});

const executeCommand = async () => {
  if (!commandInput.value.command) return;

  try {
    const args = commandInput.value.argsString
      ? commandInput.value.argsString.split(' ').filter(arg => arg.trim())
      : [];

    commandResult.value = await redisStore.executeCommand({
      command: commandInput.value.command.toUpperCase(),
      args,
    });

    $q.notify({
      type: 'positive',
      message: 'Command executed successfully',
      position: 'top',
    });
  } catch {
    $q.notify({
      type: 'negative',
      message: 'Command execution failed',
      position: 'top',
    });
  }
};

const refreshPingEntries = async () => {
  if (redisStore.isConnected) {
    await redisStore.fetchPingEntries();
  }
};

const clearAllEntries = () => {
  $q.dialog({
    title: 'Confirm',
    message: 'Are you sure you want to clear all ping entries?',
    cancel: true,
    persistent: true,
  }).onOk(() => {
    void (async () => {
      const success = await redisStore.clearPingEntries();

      if (success) {
        $q.notify({
          type: 'positive',
          message: 'All ping entries cleared',
          position: 'top',
        });
      } else {
        $q.notify({
          type: 'negative',
          message: redisStore.error || 'Failed to clear ping entries',
          position: 'top',
        });
      }
    })();
  });
};

const formatResult = (result: unknown): string => {
  if (typeof result === 'string') return result;
  return JSON.stringify(result, null, 2);
};

const formatTimestamp = (timestamp: string): string => {
  return new Date(timestamp).toLocaleString();
};
</script>
