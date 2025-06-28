//
//  Memory.h
//
//  Created by bphucc on 2025/05/25.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemoryUtils : NSObject

@property (nonatomic, strong, readonly) NSString *processName;
@property (nonatomic, readonly) pid_t processID;
@property (nonatomic, readonly) mach_port_t task;
@property (nonatomic, readonly) vm_map_offset_t baseAddress;
@property (nonatomic, readonly, getter=isValid) BOOL valid;

/**
 * Initializes the MemoryUtils with the target process name.
 * It attempts to find the process ID and obtain the Mach task port.
 *
 * @param processName The name of the process to target.
 * @return An initialized MemoryUtils object, or nil if the process cannot be found or task obtained.
 */
- (nullable instancetype)initWithProcessName:(NSString *)processName;

#pragma mark - Memory Reading

/**
 * Reads a block of memory from the target process.
 *
 * @param address The starting address to read from.
 * @param buffer A pointer to the buffer where the read data will be stored.
 * @param length The number of bytes to read.
 * @return YES if the read was successful, NO otherwise.
 */
- (BOOL)readMemoryAtAddress:(vm_address_t)address buffer:(void *)buffer length:(vm_size_t)length;

/**
 * Reads data of a specific length from the target process and returns it as NSData.
 *
 * @param address The starting address to read from.
 * @param length The number of bytes to read.
 * @return An NSData object containing the read bytes, or nil on failure.
 */
- (nullable NSData *)readDataAtAddress:(vm_address_t)address length:(vm_size_t)length;

// Convenience methods for reading common data types
- (int8_t)readInt8AtAddress:(vm_address_t)address error:(NSError **)error;
- (uint8_t)readUInt8AtAddress:(vm_address_t)address error:(NSError **)error;
- (int16_t)readInt16AtAddress:(vm_address_t)address error:(NSError **)error;
- (uint16_t)readUInt16AtAddress:(vm_address_t)address error:(NSError **)error;
- (int32_t)readInt32AtAddress:(vm_address_t)address error:(NSError **)error;
- (uint32_t)readUInt32AtAddress:(vm_address_t)address error:(NSError **)error;
- (int64_t)readInt64AtAddress:(vm_address_t)address error:(NSError **)error;
- (uint64_t)readUInt64AtAddress:(vm_address_t)address error:(NSError **)error;
- (float)readFloatAtAddress:(vm_address_t)address error:(NSError **)error;
- (double)readDoubleAtAddress:(vm_address_t)address error:(NSError **)error;

#pragma mark - Memory Writing

/**
 * Writes a block of memory to the target process.
 *
 * @param address The starting address to write to.
 * @param value A pointer to the data to be written.
 * @param length The number of bytes to write.
 * @return YES if the write was successful, NO otherwise.
 */
- (BOOL)writeMemoryAtAddress:(vm_address_t)address value:(const void *)value length:(vm_size_t)length;

/**
 * Writes NSData to the target process.
 *
 * @param data The NSData object to write.
 * @param address The starting address to write to.
 * @return YES if the write was successful, NO otherwise.
 */
- (BOOL)writeDataAtAddress:(vm_address_t)address data:(NSData *)data; // Renamed for clarity

// Convenience methods for writing common data types
- (BOOL)writeInt8AtAddress:(vm_address_t)address value:(int8_t)value error:(NSError **)error;
- (BOOL)writeUInt8AtAddress:(vm_address_t)address value:(uint8_t)value error:(NSError **)error;
- (BOOL)writeInt16AtAddress:(vm_address_t)address value:(int16_t)value error:(NSError **)error;
- (BOOL)writeUInt16AtAddress:(vm_address_t)address value:(uint16_t)value error:(NSError **)error;
- (BOOL)writeInt32AtAddress:(vm_address_t)address value:(int32_t)value error:(NSError **)error;
- (BOOL)writeUInt32AtAddress:(vm_address_t)address value:(uint32_t)value error:(NSError **)error;
- (BOOL)writeInt64AtAddress:(vm_address_t)address value:(int64_t)value error:(NSError **)error;
- (BOOL)writeUInt64AtAddress:(vm_address_t)address value:(uint64_t)value error:(NSError **)error;
- (BOOL)writeFloatAtAddress:(vm_address_t)address value:(float)value error:(NSError **)error;
- (BOOL)writeDoubleAtAddress:(vm_address_t)address value:(double)value error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END