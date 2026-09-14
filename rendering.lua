local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Terrain = Workspace:WaitForChild("Terrain")

-- ==========================================
-- PENGATURAN JEDA & OPTIMASI (Bisa diubah)
-- ==========================================
local BATCH_SIZE = 100 -- Jumlah part yang diproses sekaligus sebelum istirahat (Jangan terlalu besar)
local CYCLE_DELAY = 5 -- Jeda waktu (detik) sebelum script mengecek ulang seluruh map

local MAX_PART_SIZE = 5 -- Part di bawah ukuran ini akan dimatikan bayangannya

-- ==========================================
-- FUNGSI UNTUK MENGOPTIMASI 1 PART
-- ==========================================
local function optimizePart(part)
	-- Contoh optimasi: Mematikan bayangan pada part kecil agar FPS naik
	local size = part.Size
	if size.X < MAX_PART_SIZE and size.Y < MAX_PART_SIZE and size.Z < MAX_PART_SIZE then
		if part.CastShadow == true then
			part.CastShadow = false
		end
	end
	
	-- Anda bisa menambahkan logika lain di sini (misal mengubah transparansi, dll)
end

-- ==========================================
-- LOOP UTAMA (BERJALAN TERUS MENERUS)
-- ==========================================
task.spawn(function()
	-- Optimasi Terrain cukup dilakukan 1 kali saja di luar loop
	Terrain.WaterWaveSize = 0.1
	Terrain.WaterWaveSpeed = 10
	Terrain.WaterReflectance = 0.5
	
	while true do
		-- Ambil semua objek yang sedang ada di map (yang sudah diload oleh StreamingEnabled)
		local allObjects = Workspace:GetDescendants()
		local processedCount = 0

		for _, object in ipairs(allObjects) do
			-- Pastikan objek adalah part dan bukan Terrain
			if object:IsA("BasePart") and not object:IsA("Terrain") then
				optimizePart(object)
				processedCount = processedCount + 1

				-- SISTEM JEDA: Jika sudah memproses 100 part, beri "nafas" pada CPU
				if processedCount >= BATCH_SIZE then
					processedCount = 0
					-- Tunggu 1 frame (sepersekian detik) agar game tidak lag/freeze
					RunService.Heartbeat:Wait() 
				end
			end
		end

		-- Setelah selesai mengecek seluruh map, istirahat selama beberapa detik sebelum mengulang lagi
		task.wait(CYCLE_DELAY)
	end
end)
