# Task Alita — บันทึกส่งต่องาน

อัปเดตล่าสุด: 15 กรกฎาคม 2026

## ตำแหน่งโปรเจกต์

`D:\เอกสารอลิตา\Task-alita`

## ไฟล์สำคัญ

- `index.html` — UI และ Application logic
- `config.js` — Supabase URL และ Publishable/Anon key (ห้ามเผยแพร่ Secret/service_role)
- `supabase-db.js` — Supabase Database และ Auth client
- `supabase-schema.sql` — Tables, Trigger, RLS และ Admin/User roles

## งานที่ทำแล้ว

- ปรับ UI แนว Tailwind พร้อม Lucide icons และ Responsive layout
- เชื่อม Supabase สำหรับเพิ่ม โหลด แก้ไข และลบ Tasks/Subtasks
- เพิ่มฟิลด์วันที่ลงระบบงานและแสดงบนการ์ด
- Login/Signup ด้วยอีเมลและรหัสผ่าน
- Login ด้วย Google OAuth
- ระบบ Session และ Logout
- ระบบบทบาท `admin` และ `user`
- Admin เห็นงานทั้งหมดและเปลี่ยนบทบาทผู้ใช้ได้
- User เห็นเฉพาะงานของตัวเอง
- ป้องกันการลดสิทธิ์ Admin คนสุดท้าย
- บัญชี Google ใหม่ต้องรอ Admin อนุมัติก่อนใช้ Workspace (บังคับทั้ง UI และ RLS)
- ตาราง Admin เรียงผู้ใช้ที่รออนุมัติไว้ด้านบน พร้อมปุ่มอนุมัติ/ยกเลิกอนุมัติที่ชัดเจน
- ซ่อม/สร้าง profile อัตโนมัติเมื่อ Auth user มีอยู่แต่แถวใน profiles หาย
- เลิกใช้ single-object response ตอนอ่าน profile และมีหน้ากู้คืนพร้อม Logout เมื่อฐานข้อมูลผิดพลาด
- Modal อัปเดตรายละเอียดสามารถเลื่อนลำดับหัวข้อขึ้น/ลง และบันทึกตาม sort_order ใหม่
- แถบกรองสถานะงาน 3 ระดับคำนวณจากรายการย่อยอัตโนมัติ: ยังไม่เริ่ม/กำลังดำเนินการ/เสร็จสิ้น
- Calendar ใช้ความสูงช่องคงที่เท่ากัน และเลื่อนภายในช่องเมื่อมีหลายรายการ
- ทุกปุ่มลบข้อมูลมีข้อความยืนยันก่อนดำเนินการ ทั้งงานหลักและหัวข้อย่อย
- Backend ประเภทระบบงาน: Admin เพิ่ม/แก้ไข/เปิดปิด/ลบประเภทได้ และหน้าใช้งานโหลดประเภทจาก Supabase
- Admin allowlist ฝั่งฐานข้อมูลคืน/คงสิทธิ์ `aalita1234@gmail.com` เป็น Admin และอนุมัติอัตโนมัติ
- การอ่านโปรไฟล์กรองด้วย Auth user ID ป้องกัน Admin หยิบ profile ของ User คนอื่นมาแสดง
- Calendar เป็นปฏิทินรายเดือนจริง 6 สัปดาห์ มีนำทางเดือน/วันนี้ และจับคู่งานด้วย due_date เต็ม
- Admin จัดการคลังเทมเพลตขั้นตอนการดำเนินงานได้: สร้าง แก้ไข เปิด/ปิด และลบ โดยงานเดิมไม่เปลี่ยนตามเทมเพลต
- ส่วนจัดการระบบของ Admin เป็นหน้าเต็มแยกจาก Workspace และแบ่งแท็บผู้ใช้งาน ประเภทระบบงาน และเทมเพลตขั้นตอน
- ผู้ใช้เลือกเทมเพลตตอนสร้างงาน และระบบคัดลอกพร้อมรันเลขขั้นตอนให้อัตโนมัติ
- Admin เลือกดูงานทั้งหมดหรือเฉพาะงานของตัวเองผ่าน Toggle ได้
- การ์ดงานของ Admin แสดงอีเมลเจ้าของงาน
- List View มี Pagination 10 รายการต่อหน้า พร้อมเลขหน้าและปุ่มก่อนหน้า/ถัดไป
- Kanban แสดงเดดไลน์ และเน้นสีแดงเมื่อเลยกำหนดแต่ยังไม่เสร็จ
- Modal แยกเป็น 2 ส่วน: แก้ไขรายละเอียดหลัก และจัดการขั้นตอนการดำเนินงาน
- แก้ไขชื่อหัวข้อขั้นตอนได้ พร้อมรันเลขใหม่อัตโนมัติเมื่อเพิ่ม ลบ หรือย้ายลำดับ
- Toast แจ้งผลสำเร็จเมื่อสร้าง บันทึก ลบ อนุมัติ หรือเปลี่ยนสิทธิ์
- แก้ Responsive ไม่ให้ทั้งหน้าเลื่อนแนวนอน โดย Calendar และตาราง Admin เลื่อนเฉพาะพื้นที่ของตัวเอง
- Deploy ด้วย GitHub Pages และ GitHub Actions อัตโนมัติเมื่อ push เข้า `main`

## สิ่งที่ต้องตั้งค่าหรือทำต่อ

1. รัน `supabase-schema.sql` เวอร์ชันล่าสุดทั้งหมดใน Supabase SQL Editor
   - เวอร์ชันล่าสุดเพิ่มตาราง `workflow_templates` และ RPC สำหรับ Admin; ต้องรันก่อนบันทึกเทมเพลตจากหน้าเว็บ
2. เปิด Email provider ใน Supabase Authentication
3. เปิด Google provider และกรอก Google Client ID / Client Secret
4. เพิ่ม Supabase Callback URL ใน Google Cloud Authorized redirect URIs
5. เพิ่ม URL ของระบบใน Supabase Authentication > URL Configuration > Redirect URLs
6. Google OAuth ต้องเปิดผ่าน localhost หรือ HTTPS ไม่รองรับ `file://`

ตัวอย่างเปิดผ่าน localhost:

```powershell
cd "D:\เอกสารอลิตา\Task-alita"
python -m http.server 5500
```

จากนั้นเปิด `http://localhost:5500/index.html`

## หมายเหตุด้านความปลอดภัย

- ห้ามใส่ Secret key หรือ `service_role` key ใน `config.js`
- การสร้าง/ลบ Auth users โดย Admin ยังไม่ได้ทำในหน้าเว็บ เพราะต้องใช้ Secret key ใน Backend หรือ Supabase Edge Function
- ข้อมูลเก่าที่ไม่มี `user_id` อาจมองไม่เห็นสำหรับ User แต่ Admin สามารถเห็นได้

## แนวทางงานถัดไปที่แนะนำ

- ทดสอบ SQL และ Login จริงใน Supabase
- ทดสอบ Google OAuth ผ่าน localhost
- เพิ่ม Reset password
- เพิ่มชื่อผู้ใช้/หน่วยงานใน Profile
- เพิ่ม Edge Function หากต้องการให้ Admin เชิญหรือลบบัญชีผู้ใช้
- ย้ายจาก CDN ไปใช้ Build tooling ก่อนนำขึ้น Production

## บันทึกการสนทนาและสถานะล่าสุด (15 กรกฎาคม 2026)

ผู้ใช้ขอพัฒนาระบบต่อเนื่องและดำเนินการแล้วดังนี้:

- เพิ่มระบบอนุมัติบัญชี Google ก่อนเข้า Workspace พร้อม RLS
- เพิ่มหน้า Admin อนุมัติ/ยกเลิกอนุมัติผู้ใช้
- แก้ profile หายและเพิ่มหน้ากู้คืนพร้อม Logout
- แก้การอ่านบทบาทให้กรองด้วย Auth user ID โดยตรง
- กำหนด `aalita1234@gmail.com` ใน Admin allowlist ฝั่งฐานข้อมูล
- เพิ่มการเลื่อนลำดับหัวข้อย่อยขึ้น/ลงใน Modal
- เพิ่มแถบสถานะงานอัตโนมัติจากจำนวนรายการที่เช็ก
- ปรับ Calendar เป็นปฏิทินรายเดือนจริงและช่องมีขนาดเท่ากัน
- เพิ่มคำยืนยันก่อนลบงานหลัก หัวข้อย่อย และประเภทงาน
- เพิ่ม Backend และหน้า Admin จัดการประเภทระบบงาน

### สถานะ GitHub และ Deployment

- Repository: `https://github.com/alita-1234/task-alita`
- Visibility: Public
- Branch หลัก: `main`
- เว็บไซต์จริง: `https://alita-1234.github.io/task-alita/`
- Deployment: GitHub Actions workflow `.github/workflows/deploy-pages.yml`
- Push เข้า `main` แล้ว GitHub Pages deploy อัตโนมัติ
- `config.js` ถูกใช้ใน deployment และมีเฉพาะ Supabase anon/public key ห้ามเปลี่ยนเป็น `service_role`
- Commit ฟีเจอร์ล่าสุดก่อนบันทึกนี้: `3de39eb` — แยก Modal รายละเอียดงานและขั้นตอนการดำเนินงาน

### งานล่าสุดที่ดำเนินการในรอบนี้

- `a24ce75` แสดงเจ้าของงานสำหรับ Admin
- `aadc956` เพิ่ม Toggle งานทั้งหมด/เฉพาะงานของ Admin
- `fe591dc` เพิ่ม Pagination 10 รายการต่อหน้า
- `25f2a3a` แก้ไขและรันเลขหัวข้อขั้นตอนอัตโนมัติ
- `cbcbf17` เพิ่มตัวเลือกเทมเพลตตอนสร้างงาน
- `e5cd14e` เพิ่ม Backend และหน้า Admin จัดการเทมเพลต
- `26d19f2` แยกหน้าจัดการระบบเป็นหน้าเต็มและแท็บเมนู
- `2bd8a3a` เพิ่ม Toast แจ้งผลการทำงาน
- `834cf1b` แสดงเดดไลน์บน Kanban
- `e363f71` แก้ Horizontal overflow
- `e8c3269` รองรับแก้รายละเอียดหลักของงาน
- `3de39eb` แยก Modal รายละเอียดและขั้นตอนออกจากกัน

### จุดที่ต้องจำก่อนทำงานต่อ

- ต้องรัน `supabase-schema.sql` ล่าสุดใน Supabase SQL Editor เพื่อเปิดใช้การจัดการ `workflow_templates`
- หลังแก้โค้ดให้ commit และ push `main` แล้วตรวจ GitHub Actions จนสถานะ `success`
- GitHub CLI (`gh`) ยังไม่ได้ติดตั้ง แต่ใช้ Git Credential Manager กับ `git push` ได้แล้ว
