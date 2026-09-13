-- ==============================================
--  HAPUS DECAL | RINGAN, GAK LOOP TERUS, GAK LAG!
--  Hanya jalan saat ada perubahan — BUKAN TERUS-MENERUS! 🧊
-- ==============================================

-- ⚙️ PENGATURAN — BISA DIUBAH!
local Settings = {
    JedaAntarProses = 0.1,    -- Jeda tiap 20 objek (detik) — aman & ringan ✅
    JedaCekUlang = 30,        -- Cek ulang LAMA — tiap 30 detik saja, gak berat!
    HapusDecal = true,        -- Hapus Decal? ✅
    HapusTexture = true,      -- Hapus Texture juga? ✅
    HapusParticle = false,   -- Hapus partikel juga? (kalau butuh ubah jadi true)
    KecualikanNama = {}       -- Contoh: {"LogoServer", "EfekPenting"}
}

-- 🔧 FUNGSI: CEK HARUS DILINDUNGI?
local function Dikecualikan(nama)
    for _, kata in ipairs(Settings.KecualikanNama) do
        if string.find(nama, kata) then return true end
    end
    return false
end

-- 🔧 FUNGSI: HAPUS DECAL & TEXTURE
local function BersihkanObjek(objek)
    if not objek then return end
    if Dikecualikan(objek.Name) then return end

    -- Hapus Decal
    if Settings.HapusDecal and objek:IsA("Decal") then
        objek:Destroy()
        return true
    end

    -- Hapus Texture
    if Settings.HapusTexture and objek:IsA("Texture") then
        objek:Destroy()
        return true
    end

    -- Opsional: Hapus Partikel
    if Settings.HapusParticle and objek:IsA("ParticleEmitter") then
        objek.Enabled = false
        return true
    end

    return false
end

-- 🔄 PROSES SEMUA OBJEK — DENGAN JEDA BIAR GAK BERAT!
local function ProsesSemua()
    local semua = workspace:GetDescendants()
    local hitung = 0
    local totalDihapus = 0

    for _, obj in ipairs(semua) do
        if BersihkanObjek(obj) then
            totalDihapus += 1
        end

        -- ⏰ JEDA TIAP 20 OBJEK — BIAR GAK NGEBAN ENGINE!
        hitung += 1
        if hitung % 20 == 0 then
            task.wait(Settings.JedaAntarProses)
        end
    end

    if totalDihapus > 0 then
        print("✅ Decal/Texture dihapus:", totalDihapus)
    end
end

-- 🚀 BAGIAN PALING PENTING — GAK LOOP TERUS-MENERUS!
-- Hanya jalan: 1x saat mulai + saat ada objek baru masuk!
task.wait(1.5) -- Tunggu peta selesai dimuat dulu
ProsesSemua()

-- 🔄 DETEKSI OBJEK BARU YANG MASUK — GAK PERLU LOOP!
workspace.DescendantAdded:Connect(function(objekBaru)
    -- Tunggu sebentar biar properti selesai dimuat, lalu cek 1x
    task.wait(0.2)
    BersihkanObjek(objekBaru)
end)

-- 🔁 CEK ULANG LAMA — HANYA JAGA-JAGA, GAK BERAT!
while task.wait(Settings.JedaCekUlang) do
    ProsesSemua()
end
