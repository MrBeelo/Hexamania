package desktop

import "base:runtime"
import "core:fmt"

PRINT_ALLOCATIONS :: false

@(require_results)
heap_allocator :: proc() -> runtime.Allocator {
	return runtime.Allocator{
		procedure = heap_allocator_proc,
		data = nil,
	}
}

heap_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
    size, alignment: int, old_memory: rawptr, old_size: int, 
    location := #caller_location) -> ([]byte, runtime.Allocator_Error) {

    if PRINT_ALLOCATIONS {
    	#partial switch mode {
     	case .Alloc:
      		fmt.printfln("ALLOC: Allocated %d bytes from %v", size, location)

      	case .Alloc_Non_Zeroed:
       		fmt.printfln("ALLOC: Allocated %d non-zeroed bytes from %v", size, location)
                           
       	case .Free:
        	fmt.printfln("ALLOC: Freed %d bytes from %v", old_size, location)
                           
        case .Resize:
        	fmt.printfln("ALLOC: Resized %d -> %d bytes from %v", old_size, size, location)

        case .Resize_Non_Zeroed:
        	fmt.printfln("ALLOC: Resized %d -> %d non-zeroed bytes from %v", old_size, size, location)
        }
    }
	
    return runtime.heap_allocator_proc(allocator_data, mode, size, alignment, old_memory, old_size, location)
}