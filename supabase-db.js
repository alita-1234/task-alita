(function () {
  let client = null;

  function assertConfigured() {
    const config = window.ALITA_CONFIG;
    if (!config) throw new Error("ไม่พบไฟล์ config.js");
    if (!config.SUPABASE_URL || config.SUPABASE_URL.includes("YOUR_PROJECT_ID")) {
      throw new Error("ยังไม่ได้ตั้งค่า SUPABASE_URL");
    }
    if (!config.SUPABASE_PUBLISHABLE_KEY || config.SUPABASE_PUBLISHABLE_KEY === "YOUR_PUBLISHABLE_KEY") {
      throw new Error("ยังไม่ได้ตั้งค่า SUPABASE_PUBLISHABLE_KEY");
    }
    if (!window.supabase?.createClient) throw new Error("โหลด Supabase SDK ไม่สำเร็จ");
    return config;
  }

  function mapTask(row, ownerEmail = "") {
    return {
      id: row.id,
      userId: row.user_id || "",
      ownerEmail,
      type: row.type,
      title: row.title,
      priority: row.priority,
      dueDate: row.due_date || "",
      registeredDate: row.registered_date || "",
      status: row.status,
      subtasks: (row.subtasks || [])
        .sort((a, b) => a.sort_order - b.sort_order)
        .map(step => ({
          id: step.id,
          name: step.name,
          checked: step.checked,
          note: step.note || "",
          daysSpent: step.days_spent || 0
        }))
    };
  }

  async function connect() {
    const config = assertConfigured();
    client = window.supabase.createClient(
      config.SUPABASE_URL,
      config.SUPABASE_PUBLISHABLE_KEY,
      { auth: { persistSession: true, autoRefreshToken: true } }
    );
    return client;
  }

  async function loadTasks() {
    const { data, error } = await client
      .from(window.ALITA_CONFIG.TABLES.TASKS)
      .select("*, subtasks(*)")
      .order("created_at", { ascending: false });
    if (error) throw error;

    const rows = data || [];
    const ownerIds = [...new Set(rows.map(row => row.user_id).filter(Boolean))];
    let ownerById = new Map();
    if (ownerIds.length) {
      const { data: profiles, error: profileError } = await client
        .from("profiles")
        .select("id, email")
        .in("id", ownerIds);
      if (profileError) throw profileError;
      ownerById = new Map((profiles || []).map(profile => [profile.id, profile.email || ""]));
    }

    return rows.map(row => mapTask(row, ownerById.get(row.user_id) || ""));
  }

  async function createTask(task) {
    const { data, error } = await client
      .from(window.ALITA_CONFIG.TABLES.TASKS)
      .insert({
        type: task.type,
        title: task.title,
        priority: task.priority,
        due_date: task.dueDate || null,
        registered_date: task.registeredDate || new Date().toISOString().slice(0, 10),
        status: task.status
      })
      .select("id")
      .single();
    if (error) throw error;

    if (task.subtasks.length) {
      const rows = task.subtasks.map((step, index) => ({
        task_id: data.id,
        name: step.name,
        checked: Boolean(step.checked),
        note: step.note || "",
        days_spent: Number(step.daysSpent) || 0,
        sort_order: index
      }));
      const { error: stepError } = await client
        .from(window.ALITA_CONFIG.TABLES.SUBTASKS)
        .insert(rows);
      if (stepError) throw stepError;
    }
    return data.id;
  }

  async function updateTaskDetails(task) {
    const { error } = await client
      .from(window.ALITA_CONFIG.TABLES.TASKS)
      .update({
        title: task.title,
        type: task.type,
        priority: task.priority,
        registered_date: task.registeredDate || new Date().toISOString().slice(0, 10),
        due_date: task.dueDate || null,
        status: task.status,
        updated_at: new Date().toISOString()
      })
      .eq("id", task.id);
    if (error) throw error;
  }

  async function updateTask(task) {
    const { error } = await client
      .from(window.ALITA_CONFIG.TABLES.TASKS)
      .update({ status: task.status, updated_at: new Date().toISOString() })
      .eq("id", task.id);
    if (error) throw error;

    const { error: deleteError } = await client
      .from(window.ALITA_CONFIG.TABLES.SUBTASKS)
      .delete()
      .eq("task_id", task.id);
    if (deleteError) throw deleteError;

    if (task.subtasks.length) {
      const rows = task.subtasks.map((step, index) => ({
        task_id: task.id,
        name: step.name,
        checked: Boolean(step.checked),
        note: step.note || "",
        days_spent: Number(step.daysSpent) || 0,
        sort_order: index
      }));
      const { error: insertError } = await client
        .from(window.ALITA_CONFIG.TABLES.SUBTASKS)
        .insert(rows);
      if (insertError) throw insertError;
    }
  }

  async function deleteTask(id) {
    const { error } = await client
      .from(window.ALITA_CONFIG.TABLES.TASKS)
      .delete()
      .eq("id", id);
    if (error) throw error;
  }

  async function getSession() {
    const { data, error } = await client.auth.getSession();
    if (error) throw error;
    return data.session;
  }

  async function signIn(email, password) {
    const { data, error } = await client.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return data.session;
  }

  async function signUp(email, password) {
    const { data, error } = await client.auth.signUp({ email, password });
    if (error) throw error;
    return data;
  }

  async function signInWithGoogle(redirectTo) {
    const { data, error } = await client.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo }
    });
    if (error) throw error;
    return data;
  }

  async function signOut() {
    const { error } = await client.auth.signOut({ scope: "local" });
    if (error) throw error;
  }

  async function getMyProfile() {
    const { error: ensureError } = await client.rpc("ensure_my_profile");
    if (ensureError) throw ensureError;
    const { data: userData, error: userError } = await client.auth.getUser();
    if (userError) throw userError;
    if (!userData.user) throw new Error("ไม่พบผู้ใช้ที่เข้าสู่ระบบ");
    const { data, error } = await client
      .from("profiles")
      .select("id, email, role, is_approved, created_at")
      .eq("id", userData.user.id)
      .limit(1);
    if (error) throw error;
    if (!data?.length) throw new Error("ไม่พบโปรไฟล์ผู้ใช้ กรุณารัน supabase-schema.sql เวอร์ชันล่าสุด");
    return data[0];
  }

  async function listUsers() {
    const { data, error } = await client.from("profiles").select("id, email, role, is_approved, created_at").order("created_at", { ascending: true });
    if (error) throw error;
    return data || [];
  }

  async function setUserRole(userId, role) {
    const { error } = await client.rpc("admin_set_user_role", { target_user_id: userId, new_role: role });
    if (error) throw error;
  }

  async function setUserApproval(userId, approved) {
    const { error } = await client.rpc("admin_set_user_approval", { target_user_id: userId, approved });
    if (error) throw error;
  }

  async function listTaskTypes() {
    const { data, error } = await client.from("task_types")
      .select("code, name, template_kind, is_active, sort_order")
      .order("sort_order", { ascending: true });
    if (error) throw error;
    return data || [];
  }

  async function saveTaskType(type) {
    const { error } = await client.rpc("admin_save_task_type", {
      type_code: type.code,
      type_name: type.name,
      type_template_kind: type.templateKind,
      type_is_active: type.isActive
    });
    if (error) throw error;
  }

  async function deleteTaskType(code) {
    const { error } = await client.rpc("admin_delete_task_type", { type_code: code });
    if (error) throw error;
  }

  async function listWorkflowTemplates() {
    const { data, error } = await client.from("workflow_templates")
      .select("id, name, description, recommended_kind, steps, is_active, sort_order")
      .order("sort_order", { ascending: true });
    if (error) {
      if (["42P01", "PGRST205"].includes(error.code)) return [];
      throw error;
    }
    return (data || []).map(template => ({
      id: template.id,
      name: template.name,
      description: template.description || "",
      recommendedKind: template.recommended_kind,
      steps: Array.isArray(template.steps) ? template.steps : [],
      isActive: template.is_active,
      sortOrder: template.sort_order
    }));
  }

  async function saveWorkflowTemplate(template) {
    const { data, error } = await client.rpc("admin_save_workflow_template", {
      template_id: template.id || null,
      template_name: template.name,
      template_description: template.description || "",
      template_recommended_kind: template.recommendedKind,
      template_steps: template.steps,
      template_is_active: template.isActive
    });
    if (error) throw error;
    return data;
  }

  async function deleteWorkflowTemplate(id) {
    const { error } = await client.rpc("admin_delete_workflow_template", { template_id: id });
    if (error) throw error;
  }

  window.AlitaDB = Object.freeze({
    connect, loadTasks, createTask, updateTaskDetails, updateTask, deleteTask,
    getSession, signIn, signUp, signInWithGoogle, signOut,
    getMyProfile, listUsers, setUserRole, setUserApproval,
    listTaskTypes, saveTaskType, deleteTaskType,
    listWorkflowTemplates, saveWorkflowTemplate, deleteWorkflowTemplate
  });
})();
