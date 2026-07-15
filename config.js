/**
 * Supabase configuration for Alita Task Workspace.
 *
 * ใช้เฉพาะ Publishable key (แนะนำ) หรือ anon public key เท่านั้น
 * ห้ามใส่ Secret key หรือ service_role key ในไฟล์นี้
 */
window.ALITA_CONFIG = Object.freeze({
  SUPABASE_URL: "https://wojidufqcdvwtfxcxblr.supabase.co",
  SUPABASE_PUBLISHABLE_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvamlkdWZxY2R2d3RmeGN4YmxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwODExMzcsImV4cCI6MjA5OTY1NzEzN30.Q5ZBvSm6SNrnyhk-EX2rc8fbsOyZTpPY1zz0xYkfnlA",

  // ชื่อตารางที่จะใช้เมื่อเชื่อมฐานข้อมูลในขั้นตอนถัดไป
  TABLES: Object.freeze({
    TASKS: "tasks",
    SUBTASKS: "subtasks"
  })
});

