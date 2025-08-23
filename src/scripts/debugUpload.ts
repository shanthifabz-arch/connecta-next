(async () => {
  try {
    console.log("Debug script started");
  } catch (err) {
    console.error("Caught error at top level:", err);
  }
})();

