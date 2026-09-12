-- ==============================================
--  HAPUS BAYANGAN + OPTIMASI | RINGAN & AMAN
--  Ada jeda biar gak bikin lag/berat 🧊
-- ==============================================

-- ⚙️ PENGATURAN — BISA DIUBAH SESUAI SELERA!
local Settings = {
    JedaAntarObjek = 0.1,      -- Jeda antar objek (detik) — 0.1 = 100ms, aman & ringan ✅
    JedaUlangCek = 5,          -- Cek ulang tiap 5 detik untuk objek baru
    HapusDiWorkspace = true,   -- Hapus bayangan di peta
    HapusDiKarakter = true,    -- Hapus bayangan pemain
    HapusDiAsetLain = true,    -- Hapus bayangan di model lain
}

-- 🔧 FUNGSI UTAMA: HAPUS BAYANGAN
local function HapusBayangan(objek)
    if not objek then return end

    -- Cari komponen bayangan
    local bayangan = objek:FindFirstChildOfClass("SpotLight") or 
                     objek:FindFirstChildOfClass("PointLight") or
                     objek:FindFirstChild("Shadow") or
                     objek:FindFirstChild("CastShadow")

    -- Matikan bayangan di bagian bagian
    if objek:IsA("BasePart") then
        objek.CastShadow = false  -- ✅ Matikan bayangan tanpa hapus objek
        objek.ReceiveShadow = false
    end
end

-- 🔄 PROSES SCAN DENGAN JEDA
local function ProsesSemuaObjek()
    local semuaObjek = workspace:GetDescendants()
    local hitung = 0

    for _, objek in ipairs(semuaObjek) do
        -- Filter sesuai pengaturan
        local namaObjek = objek.Parent and objek.Parent.Name or ""
        
        -- Lewati karakter pemain kalau diminta
        if not Settings.HapusDiKarakter and namaObjek == "HumanoidRootPart" then
            continue
        end

        -- Proses matikan bayangan
        HapusBayangan(objek)

        -- ⏰ Jeda setiap 20 objek biar gak berat!
        hitung += 1
        if hitung % 20 == 0 then
            task.wait(Settings.JedaAntarObjek)
        end
    end

    print("✅ Semua bayangan dimatikan! Total diproses:", #semuaObjek)
end

-- 🚀 MULAI PROSES PERTAMA KALI
task.wait(1) -- Tunggu game siap dulu
ProsesSemuaObjek()

-- 🔄 CEK ULANG SECARA BERKALA (untuk objek baru yang masuk)
while task.wait(Settings.JedaUlangCek) do
    ProsesSemuaObjek()
end
