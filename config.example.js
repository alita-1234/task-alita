/**
 * Copy this file to config.js and fill in your Supabase project values.
 * Use only a Publishable key or anon public key. Never use service_role here.
 */
window.ALITA_CONFIG = Object.freeze({
  SUPABASE_URL: "https://YOUR_PROJECT_REF.supabase.co",
  SUPABASE_PUBLISHABLE_KEY: "YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY",

  TABLES: Object.freeze({
    TASKS: "tasks",
    SUBTASKS: "subtasks"
  })
});
