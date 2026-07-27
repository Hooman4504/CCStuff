-- Automatically find the block reader peripheral connected to the computer
local reader = peripheral.find("block_reader")

-- Check if the peripheral is successfully attached
if not reader then
    error("Error: No 'block_reader' peripheral found! Make sure it's attached.")
end

print("Scanning block in front of the Block Reader...\n")

-- 1. Get basic block name (e.g., minecraft:chest)
local blockName = reader.getBlockName()
print("Block Name: " .. tostring(blockName))

-- 2. Check if the block has a block entity / tile entity data
local hasEntity = reader.hasBlockEntity and reader.hasBlockEntity() or true

if hasEntity then
    -- 3. Retrieve the NBT / block data table
    local blockData = reader.getBlockData()
    
    if blockData then
        print("\n--- Retrieved Block Data (NBT) ---")
        
        -- Recursive function to neatly print nested tables (like inventories or fluid contents)
        local function printTable(t, indent)
            indent = indent or ""
            for key, value in pairs(t) do
                if type(value) == "table" then
                    print(indent .. tostring(key) .." (Table):")
                    printTable(value, indent .. "  ")
                else
                    print(indent .. tostring(key) .. ": " .. tostring(value))
                end
            end
        end
        
        printTable(blockData)
    else
        print("\nNo block data (NBT) found. The target might be a standard block without tile data.")
    end
else
    print("\nThis block does not have an associated block entity.")
end