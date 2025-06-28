#import "Memory.h"
#import <errno.h>

extern "C" kern_return_t mach_vm_region_recurse(
                                vm_map_t                 map,
                                mach_vm_address_t        *address,
                                mach_vm_size_t           *size,
                                uint32_t                 *depth,
                                vm_region_recurse_info_t info,
                                mach_msg_type_number_t   *infoCnt
                            );

extern "C" kern_return_t mach_vm_write(
                                vm_map_t                          map,
                                mach_vm_address_t                 address,
                                pointer_t                         data,
                                __unused mach_msg_type_number_t   size
                            );

@interface MemoryUtils ()
// Redeclare properties as readwrite for internal use
@property (nonatomic, strong, readwrite) NSString *processName;
@property (nonatomic, readwrite) pid_t processID;
@property (nonatomic, readwrite) mach_port_t task;
@property (nonatomic, readwrite) vm_map_offset_t baseAddress;
@property (nonatomic, readwrite, getter=isValid) BOOL valid;
@end

@implementation MemoryUtils

- (nullable instancetype)initWithProcessName:(NSString *)processName {
    NSLog(@"[DEBUG] MemoryUtils initWithProcessName: %@", processName);
    
    self = [super init];
    if (self) {
        _processName = processName;
        _task = MACH_PORT_NULL;
        _processID = -1;
        _baseAddress = 0;
        _valid = NO;

        const char *processNameCStr = [processName UTF8String];
        if (!processNameCStr) {
            NSLog(@"Error: Could not convert process name to C string.");
            return nil;
        }

        NSLog(@"[DEBUG] Getting PID for process: %s", processNameCStr);
        _processID = [self GetProcessPIDByName:processNameCStr];
        if (_processID <= 0) {
            NSLog(@"Error: Could not find process ID for '%@'. Ensure the process is running and you have permissions.", processName);
            return nil;
        }
        
        NSLog(@"[DEBUG] Found PID: %d, getting task port", _processID);
        kern_return_t kret = task_for_pid(mach_task_self(), _processID, &_task);
        if (kret != KERN_SUCCESS) {
            NSLog(@"Error: task_for_pid failed for PID %d with error %d (%s). Check permissions.", _processID, kret, mach_error_string(kret));
            _task = MACH_PORT_NULL;
            return nil;
        }
        
        NSLog(@"[DEBUG] Got task port: %u, getting base address", _task);
        _baseAddress = [self GetModuleBaseForTask:_task];
        if (_baseAddress == 0) {
            NSLog(@"Warning: Could not determine a base address for PID %d. This might be normal for some processes or indicate an issue.", _processID);
        }
        
        NSLog(@"[DEBUG] Base address: 0x%llx, setting valid=YES", _baseAddress);
        _valid = YES;
    }
    return self;
}

- (pid_t)GetProcessPIDByName:(const char *)processNameCStr {
    NSLog(@"[DEBUG] GetProcessPIDByName called with: %s", processNameCStr);
    
    size_t length = 0;
    static const int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};

    int err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, NULL, &length, NULL, 0);
    if (err == -1) {
        err = errno;
        NSLog(@"sysctl (size check) failed: %s", strerror(err));
        return -1;
    }
    if (err != 0 && length == 0) {
         NSLog(@"sysctl (size check) failed or returned no data, err: %d", err);
         return -1;
    }

    struct kinfo_proc *procBuffer = (struct kinfo_proc *)malloc(length);
    if (procBuffer == NULL) {
        NSLog(@"Failed to allocate memory for process buffer.");
        return -1;
    }

    err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, procBuffer, &length, NULL, 0);
     if (err == -1) {
        err = errno;
        NSLog(@"sysctl (data fetch) failed: %s", strerror(err));
        free(procBuffer);
        return -1;
    }
    if (err != 0) {
        NSLog(@"sysctl (data fetch) failed with error code: %d", err);
        free(procBuffer);
        return -1;
    }

    int count = (int)(length / sizeof(struct kinfo_proc));
    NSLog(@"[DEBUG] Found %d processes, searching for: %s", count, processNameCStr);
    
    // Debug: List first 10 process names to see what's available
    int debugCount = MIN(count, 10);
    for (int i = 0; i < debugCount; ++i) {
        NSLog(@"[DEBUG] Process %d: PID=%d, Name='%s'", i, procBuffer[i].kp_proc.p_pid, procBuffer[i].kp_proc.p_comm);
    }
    
    for (int i = 0; i < count; ++i) {
        // Ensure process name is not NULL before comparing
        if (procBuffer[i].kp_proc.p_comm[0] != '\0' && strcmp(procBuffer[i].kp_proc.p_comm, processNameCStr) == 0) {
            pid_t processPID = procBuffer[i].kp_proc.p_pid;
            NSLog(@"[DEBUG] Found matching process: %s with PID: %d", processNameCStr, processPID);
            free(procBuffer);
            return processPID;
        }
    }

    NSLog(@"[DEBUG] Process '%s' not found among %d processes", processNameCStr, count);
    free(procBuffer);
    return -1;
}

- (vm_map_offset_t)GetModuleBaseForTask:(mach_port_t)taskToInspect {
    vm_map_offset_t vmoffset = 0;
    vm_map_size_t vmsize = 0;
    uint32_t nesting_depth = 1; // Start with depth 1 for top-level regions
    struct vm_region_submap_info_64 vbr;
    mach_msg_type_number_t vbrcount = VM_REGION_SUBMAP_INFO_COUNT_64;
    mach_vm_address_t current_address = 0; // Start search from address 0

    // Get the first region.
    kern_return_t kret = mach_vm_region_recurse(taskToInspect, &current_address, &vmsize,
                                                &nesting_depth,
                                                (vm_region_recurse_info_t)&vbr,
                                                &vbrcount);

    if (kret != KERN_SUCCESS) {
        NSLog(@"mach_vm_region_recurse failed: %s", mach_error_string(kret));
        return 0;
    }
    vmoffset = current_address; // The address of the first region found
    return vmoffset;
}

#pragma mark - Memory Reading Implementation

- (BOOL)readMemoryAtAddress:(vm_address_t)address buffer:(void *)buffer length:(vm_size_t)length {
    if (!self.isValid || self.task == MACH_PORT_NULL) {
        NSLog(@"ReadMemory: Task is not valid.");
        return NO;
    }
    if (address == 0 && length > 0) { // Reading from address 0 is usually problematic
        NSLog(@"ReadMemory: Attempting to read from null address.");
        // Allow reading 0 bytes from address 0, though it's a no-op.
        if (length > 0) return NO;
    }
    if (length == 0) { // Reading 0 bytes is technically successful.
        return YES;
    }

    vm_size_t bytesRead = 0;
    kern_return_t kret = vm_read_overwrite(self.task, address, length, (vm_address_t)buffer, &bytesRead);

    if (kret != KERN_SUCCESS) {
        NSLog(@"vm_read_overwrite failed at address 0x%llx for length %llu: %s", (unsigned long long)address, (unsigned long long)length, mach_error_string(kret));
        return NO;
    }

    if (bytesRead != length) {
        NSLog(@"vm_read_overwrite read %llu bytes, expected %llu bytes at address 0x%llx", (unsigned long long)bytesRead, (unsigned long long)length, (unsigned long long)address);
        return NO;
    }
    return YES;
}

- (nullable NSData *)readDataAtAddress:(vm_address_t)address length:(vm_size_t)length {
    if (length == 0) {
        return [NSData data];
    }
    NSMutableData *data = [NSMutableData dataWithLength:length];
    if (!data) {
        NSLog(@"Failed to allocate NSMutableData of length %llu", (unsigned long long)length);
        return nil;
    }
    if ([self readMemoryAtAddress:address buffer:[data mutableBytes] length:length]) {
        return data;
    }
    return nil;
}

#define IMPLEMENT_READ_TYPE(Type, TypeName) \
- (Type)read##TypeName##AtAddress:(vm_address_t)address error:(NSError **)error { \
    Type value; \
    if ([self readMemoryAtAddress:address buffer:&value length:sizeof(Type)]) { \
        if (error) *error = nil; \
        return value; \
    } else { \
        if (error) { \
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to read %s at address 0x%llx", #TypeName, (unsigned long long)address]}; \
            *error = [NSError errorWithDomain:@"MemoryUtilsErrorDomain" code:1001 userInfo:userInfo]; \
        } \
        return (Type)0; \
    } \
}

IMPLEMENT_READ_TYPE(int8_t, Int8)
IMPLEMENT_READ_TYPE(uint8_t, UInt8)
IMPLEMENT_READ_TYPE(int16_t, Int16)
IMPLEMENT_READ_TYPE(uint16_t, UInt16)
IMPLEMENT_READ_TYPE(int32_t, Int32)
IMPLEMENT_READ_TYPE(uint32_t, UInt32)
IMPLEMENT_READ_TYPE(int64_t, Int64)
IMPLEMENT_READ_TYPE(uint64_t, UInt64)
IMPLEMENT_READ_TYPE(float, Float)
IMPLEMENT_READ_TYPE(double, Double)

#pragma mark - Memory Writing Implementation

- (BOOL)writeMemoryAtAddress:(vm_address_t)address value:(const void *)value length:(vm_size_t)length {
    if (!self.isValid || self.task == MACH_PORT_NULL) {
        NSLog(@"WriteMemory: Task is not valid.");
        return NO;
    }
     if (address == 0 && length > 0) { // Writing to address 0 is usually problematic
        NSLog(@"WriteMemory: Attempting to write to null address.");
        if (length > 0) return NO;
    }
    if (length == 0) { // Writing 0 bytes is technically successful.
        return YES;
    }
    if (value == NULL && length > 0) { // Cannot write from a NULL buffer if length > 0
        NSLog(@"WriteMemory: Attempting to write from a NULL buffer.");
        return NO;
    }

    // Note: mach_vm_write expects a `pointer_t` which is `vm_offset_t` (unsigned int on 32-bit, unsigned long on 64-bit).
    // Casting `const void *` to `pointer_t` (which is `(vm_offset_t)value`) is standard practice here.
    kern_return_t kret = mach_vm_write(self.task, address, (pointer_t)value, (mach_msg_type_number_t)length);

    if (kret != KERN_SUCCESS) {
        NSLog(@"mach_vm_write failed at address 0x%llx for length %llu: %s", (unsigned long long)address, (unsigned long long)length, mach_error_string(kret));
        return NO;
    }
    return YES;
}

- (BOOL)writeDataAtAddress:(vm_address_t)address data:(NSData *)data {
    if (!data) {
        NSLog(@"WriteData: Input data is nil.");
        return NO; // Or handle as writing 0 bytes if preferred
    }
    return [self writeMemoryAtAddress:address value:[data bytes] length:[data length]];
}


#define IMPLEMENT_WRITE_TYPE(Type, TypeName) \
- (BOOL)write##TypeName##AtAddress:(vm_address_t)address value:(Type)value error:(NSError **)error { \
    if ([self writeMemoryAtAddress:address value:&value length:sizeof(Type)]) { \
        if (error) *error = nil; \
        return YES; \
    } else { \
        if (error) { \
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to write %s at address 0x%llx", #TypeName, (unsigned long long)address]}; \
            *error = [NSError errorWithDomain:@"MemoryUtilsErrorDomain" code:1002 userInfo:userInfo]; \
        } \
        return NO; \
    } \
}

IMPLEMENT_WRITE_TYPE(int8_t, Int8)
IMPLEMENT_WRITE_TYPE(uint8_t, UInt8)
IMPLEMENT_WRITE_TYPE(int16_t, Int16)
IMPLEMENT_WRITE_TYPE(uint16_t, UInt16)
IMPLEMENT_WRITE_TYPE(int32_t, Int32)
IMPLEMENT_WRITE_TYPE(uint32_t, UInt32)
IMPLEMENT_WRITE_TYPE(int64_t, Int64)
IMPLEMENT_WRITE_TYPE(uint64_t, UInt64)
IMPLEMENT_WRITE_TYPE(float, Float)
IMPLEMENT_WRITE_TYPE(double, Double)

- (void)dealloc {
    if (_task != MACH_PORT_NULL) {
        kern_return_t kret = mach_port_deallocate(mach_task_self(), _task);
        if (kret != KERN_SUCCESS) {
            NSLog(@"Failed to deallocate mach port %u: %s", _task, mach_error_string(kret));
        }
        _task = MACH_PORT_NULL;
    }
    NSLog(@"MemoryUtils for %@ deallocated.", self.processName);
}

@end