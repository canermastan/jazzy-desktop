// A magical Proxy object that forwards all method calls to the Nim backend
export const jazzy = new Proxy({}, {
  get: function(target, prop) {
    return async function(...args) {
      if (typeof window[prop] === 'function') {
        const response = await window[prop](...args);
        // Our Nim backend returns { message: result } for now
        return response.message;
      } else {
        throw new Error(`Nim function '${prop}' is not exposed.`);
      }
    };
  }
});
