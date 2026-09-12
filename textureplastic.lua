-- ==============================================
--  UBAH TEKSTUR JADI PLASTIK | RINGAN + JEDA
--  Gak bikin lag, gak berat 🧊✨
-- ==============================================

-- ⚙️ PENGATURAN — BISA DIUBAH!
local Settings = {
    TeksturTarget = Enum.Material.SmoothPlastic,  -- ✅ TEKSTUR PLASTIK
    JedaAntarProses = 0.08,                        -- Jeda tiap 25 objek (detik) — aman & ringan!
    JedaCekUlang = 8,                              -- Cek objek baru tiap 8 detik
    UbahKarakterPemain = true,                     -- Ikut ubah karakter pemain?
    UbahBagianPeta = true,                         -- Ikut ubah peta/bangunan?
    UbahPartLain = true,                           -- Ikut ubah part/model lain?
}

-- 🔧 FUNGSI: UBAH TEKSTUR SATU OBJEK
local function UbahKePlastik(part)
    if not part or not part:IsA("BasePart") then return end

    -- Lewati kalau karakter pemain diminta TIDAK ikut diubah
    if not Settings.UbahKarakterPemain then
        local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then return end
    end

    -- ✅ Ubah material jadi Plastik Halus
    part.Material = Settings.TeksturTarget

    -- Opsional: biar makin kelihatan plastik
    part.CastShadow = false  -- Matikan bayangan biar makin bersih
end

-- 🔄 PROSES SEMUA OBJEK DENGAN JEDA
local function ProsesSemuaObjek()
    local semuaPart = workspace:GetDescendants()
    local hitung = 0

    for _, part in ipairs(semuaPart) do
        -- Filter sesuai pengaturan
        if part:IsA("BasePart") then
            UbahKePlastik(part)
            hitung += 1

            -- ⏰ Jeda tiap 25 objek — BIAR GAK BERAT!
            if hitung % 25 == 0 then
                task.wait(Settings.JedaAntarProses)
            end
        end
    end

    print("✅ Selesai! Total diubah jadi Plastik:", hitung)
end

-- 🚀 MULAI PROSES
task.wait(1.5) -- Tunggu peta & objek selesai dimuat dulu
ProsesSemuaObjek()

-- 🔄 CEK ULANG OBJEK BARU YANG MASUK
while task.wait(Settings.JedaCekUlang) do
    ProsesSemuaObjek()
end
