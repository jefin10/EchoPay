// In-memory stand-in for expo-sqlite/kv-store in unit tests.
const store = new Map();

module.exports = {
  __esModule: true,
  default: {
    getItemSync: (k) => (store.has(k) ? store.get(k) : null),
    setItemSync: (k, v) => void store.set(k, v),
    removeItemSync: (k) => store.delete(k),
    clearSync: () => {
      store.clear();
      return true;
    },
  },
};
