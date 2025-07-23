const memory = @import("memory");
const options = @import("options.zig");

pub fn DMA() type {
    return struct {
        const Self = @This();
        const dma_transfer_register: u16 = 0xFF46;
        const oam_start_address: u16 = 0xFE00;
        const oam_size: u8 = 0xA0;

        // External pointers
        mmu: *memory.MemoryManagementUnit(),

        // Track the current DMA source address
        dma_start_address: u8,
        oam_offset: u8,
        dma_transferring: bool,

        pub fn init(opts: options.SoCOptions) Self {
            return .{
                .mmu = opts.mmu,

                .dma_start_address = opts.mmu.getMemory(dma_transfer_register),
                .oam_offset = 0,
                .dma_transferring = false,
            };
        }

        pub fn deinit(_: *Self) void {}

        pub fn machineTick(self: *Self) void {
            // Compare last start address against current start address
            // (Re)start transfer if it changed
            if (self.dma_start_address != self.mmu.getMemory(dma_transfer_register)) {
                // Reset transfer state
                self.dma_start_address = self.mmu.getMemory(dma_transfer_register);
                self.oam_offset = 0;

                self.dma_transferring = true;
            }

            if (self.dma_transferring) {
                self.transfer();
            }
        }

        fn transfer(self: *Self) void {
            if (self.oam_offset < oam_size) {
                // Transfer one byte
                const source_address: u16 = @as(u16, @intCast(self.dma_start_address)) << 8 | self.oam_offset;
                const source_value: u8 = self.mmu.getMemory(source_address);

                self.mmu.setMemory(oam_start_address | self.oam_offset, source_value);

                self.oam_offset += 1;
            } else {
                // Done transferring
                self.dma_transferring = false;
            }
        }
    };
}
