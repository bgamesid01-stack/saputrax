-- ==============================================
--  HAPUS SEMUA PARTIKEL | RINGAN + JEDA
--  Hilangkan efek asap, api, debu, dll 🚫✨
-- ==============================================

-- ⚙️ PENGATURAN — BISA DIUBAH!
local Settings = {
    JedaAntarProses = 0.08,    -- Jeda tiap 15 objek (detik) — aman & gak berat!
    JedaCekUlang = 6,          -- Cek ulang tiap 6 detik (untuk partikel baru)
    HapusDiKarakter = true,    -- Hapus partikel di pemain juga?
    HapusDiPeta = true,        -- Hapus partikel di peta/bangunan?
    HapusDiSkillItem = true,   -- Hapus partikel dari senjata/skill?
    -- Opsional: JANGAN hapus yang namanya mengandung kata ini
    PengecualianNama = {}      -- Contoh: {"ApiPelindung", "EfekSpesial"}
}

-- 🔧 FUNGSI: CEK APAKAH HARUS DILINDUNGI
local function Dikecualikan(nama)
    for _, kata in ipairs(Settings.PengecualianNama) do
        if string.find(nama, kata) then return true end
    end
    return false
end

-- 🔧 FUNGSI: HAPUS/MATIKAN PARTIKEL
local function MatikanPartikel(efek)
    if not efek then return end
    if Dikecualikan(efek.Name) then return end

    -- ✅ Matikan partikel (bukan hapus objek, biar gak rusak script lain!)
    if efek:IsA("ParticleEmitter") then
        efek.Enabled = false
        -- Opsional: hapus juga kalau mau lebih bersih
        -- efek:Destroy()
    end

    -- ✅ Matikan efek cahaya/kilau
    if efek:IsA("SpotLight") or efek:IsA("PointLight") or efek:IsA("SurfaceLight") then
        efek.Enabled = false
    end

    -- ✅ Matikan efek suara partikel juga
    if efek:IsA("Sound") then
        efek.Volume = 0
    end
end

-- 🔄 PROSES SEMUA OBJEK DENGAN JEDA
local function ProsesSemuaEfek()
    local semuaEfek = workspace:GetDescendants()
    local hitung = 0
    local totalDimatikan = 0

    for _, efek in ipairs(semuaEfek) do
        -- Filter area sesuai pengaturan
        local lokasi = efek.Parent
        local diKarakter = lokasi and lokasi:FindFirstChildOfClass("Humanoid")

        if diKarakter and not Settings.HapusDiKarakter then continue end

        -- Proses matikan
        if efek:IsA("ParticleEmitter") then
            MatikanPartikel(efek)
            totalDimatikan += 1
        elseif efek:IsA("SpotLight") or efek:IsA("PointLight") or efek:IsA("SurfaceLight") then
            MatikanPartikel(efek)
        end

        hitung += 1

        -- ⏰ JEDA TIAP 15 OBJEK — BIAR GAK BERAT!
        if hitung % 15 == 0 then
            task.wait(Settings.JedaAntarProses)
        end
    end

    if totalDimatikan > 0 then
        print("✅ Partikel dimatikan:", totalDimatikan)
    end
end

-- 🚀 MULAI PROSES
task.wait(1) -- Tunggu peta selesai dimuat dulu
ProsesSemuaEfek()

-- 🔄 CEK ULANG PARTIKEL BARU
while task.wait(Settings.JedaCekUlang) do
    ProsesSemuaEfek()
end
