import Foundation

extension Utilities {
    static func tearDecode(file: String, seed: String) throws -> String {
        let key = String(seed.map {
            switch $0 {
            case "0": return "5"
            case "1": return "6"
            case "2": return "7"
            case "5": return "0"
            case "6": return "1"
            case "7": return "2"
            default: return $0
            }
        })
        guard !file.isEmpty else {
            throw ProviderError.noContent
        }
        let fileAsset = String(Self.decrypt(ascii: file, keystr: key).map {
            switch $0 {
            case "0": return "5"
            case "1": return "6"
            case "2": return "7"
            case "5": return "0"
            case "6": return "1"
            case "7": return "2"
            default: return $0
            }
        })
        return fileAsset
    }
    // Swift port of https://github.com/gitpan/Crypt-Tea_JS
    static func rshift(lhs: Int32, rhs: Int32) -> Int32 {
        Int32(bitPattern: UInt32(bitPattern: lhs) >> UInt32(rhs))
    }

    static func str2bytes(ascii: String) -> [Int32] {
        ascii.compactMap { Int32($0.asciiValue ?? 0) }
    }

    static func bytes2str(chars: [Int32]) -> String {
        let data = Data(bytes: chars, count: chars.count * MemoryLayout<Int32>.stride)
        let ascii = String(data: data, encoding: .utf32LittleEndian)!
        return ascii
    }

    static func digest_pad(chars: [Int32]) -> [Int32] {
        var newarray: [Int32] = []
        var ina: Int32 = 0
        var iba: Int = 0
        let nba = chars.count
        let npads: Int32 = 15 - Int32(nba % 16)
        newarray.append(npads)
        ina += 1
        while iba < nba {
            newarray.append(chars[safe: iba] ?? 0)
            ina += 1
            iba += 1
        }
        var ip = npads
        while ip > 0 {
            newarray.append(0)
            ina += 1
            ip -= 1
        }
        return newarray
    }

    static func blocks2bytes(blocks: [Int32]) -> [Int32] {
        var bytes: [Int32] = []
        var ibl = 0
        while ibl < blocks.count {
            bytes += [0xFF & rshift(lhs: blocks[safe: ibl] ?? 0, rhs: 24)]
            bytes += [0xFF & rshift(lhs: blocks[safe: ibl] ?? 0, rhs: 16)]
            bytes += [0xFF & rshift(lhs: blocks[safe: ibl] ?? 0, rhs: 8)]
            bytes += [0xFF & (blocks[safe: ibl] ?? 0)]
            ibl += 1
        }
        return bytes
    }

    static func bytes2blocks(bytes: [Int32]) -> [Int32] {
        var blocks: [Int32] = []
        var ibl = 0
        var iby = 0
        let nby = bytes.count
        while true {
            blocks.append((0xFF & (bytes[safe: iby] ?? 0)) << 24)
            iby += 1
            if iby >= nby { break }
            blocks[ibl] |= (0xFF & (bytes[safe: iby] ?? 0)) << 16
            iby += 1
            if iby >= nby { break }
            blocks[ibl] |= (0xFF & (bytes[safe: iby] ?? 0)) << 8
            iby += 1
            if iby >= nby { break }
            blocks[ibl] |= 0xFF & (bytes[safe: iby] ?? 0)
            iby += 1
            if iby >= nby { break }
            ibl += 1
        }
        return blocks
    }

    static func xor_blocks(blk1: [Int32], blk2: [Int32]) -> [Int32] {
        [(blk1[safe: 0] ?? 0) ^ (blk2[safe: 0] ?? 0), (blk1[safe: 1] ?? 0) ^ (blk2[safe: 1] ?? 0)]
    }

    // remove no of pad chars at end specified by 1 char ('0'..'7') at front
    static func unpad(chars: [Int32]) -> [Int32] {
        var iba = 0
        var newarray: [Int32] = []
        let npads = 0x7 & (chars[safe: iba] ?? 0)
        iba += 1
        let nba = Int32(chars.count) - npads
        while iba < nba {
            newarray += [(chars[safe: iba] ?? 0)]
            iba += 1
        }
        return newarray
    }

    // returns 22-char ascii signature
    static func binarydigest(ascii: String) -> [Int32] {
        let key: [Int32] = [0x6162_6364, 0x6263_6465, 0x6364_6566, 0x6465_6667]
        var c0: [Int32] = [0x6162_6364, 0x6263_6465]
        var c1 = c0

        var v0: [Int32] = [0, 0]
        var v1: [Int32] = [0, 0]
        var swap: Int32
        let blocks: [Int32] = bytes2blocks(bytes: digest_pad(chars: str2bytes(ascii: ascii)))
        var ibl = 0
        while ibl < blocks.count {
            v0[0] = blocks[safe: ibl] ?? 0
            ibl += 1
            v0[1] = blocks[safe: ibl] ?? 0
            ibl += 1
            v1[0] = blocks[safe: ibl] ?? 0
            ibl += 1
            v1[1] = blocks[safe: ibl] ?? 0
            ibl += 1
            c0 = tea_code(value: xor_blocks(blk1: v0, blk2: c0), key: key)
            c1 = tea_code(value: xor_blocks(blk1: v1, blk2: c1), key: key)
            swap = c0[0]
            c0[0] = c0[1]
            c0[1] = c1[0]
            c1[0] = c1[1]
            c1[1] = swap
        }

        return [c0[0], c0[1], c1[0], c1[1]]
    }

    // converts pseudo-base64 to array of bytes
    static func ascii2bytes(ascii: String) -> [Int32] {
        let a2b = [
            "A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5, "G": 6, "H": 7, "I": 8, "J": 9, "K": 10,
            "L": 11, "M": 12, "N": 13, "O": 14, "P": 15, "Q": 16, "R": 17, "S": 18, "T": 19, "U": 20,
            "V": 21, "W": 22, "X": 23, "Y": 24, "Z": 25, "a": 26, "b": 27, "c": 28, "d": 29, "e": 30,
            "f": 31, "g": 32, "h": 33, "i": 34, "j": 35, "k": 36, "l": 37, "m": 38, "n": 39, "o": 40,
            "p": 41, "q": 42, "r": 43, "s": 44, "t": 45, "u": 46, "v": 47, "w": 48, "x": 49, "y": 50,
            "z": 51, "0": 52, "1": 53, "2": 54, "3": 55, "4": 56, "5": 57, "6": 58, "7": 59, "8": 60,
            "9": 61, "-": 62, "_": 63
        ]

        var ia = -1
        let la = ascii.count
        var ib = 0
        var b: [Int32] = []
        var carry: Int32

        while true {
            while true {
                ia += 1
                if ia >= la { return b }

                if a2b[ascii[ia..<ia + 1]] != nil { break }
            }
            b.insert(Int32(a2b[ascii[ia..<ia + 1]] ?? 0) << 2, at: ib)

            while true {
                ia += 1
                if ia >= la { return b }
                if a2b[ascii[ia..<ia + 1]] != nil { break }
            }
            carry = Int32(a2b[ascii[ia..<ia + 1]] ?? 0)
            b[ib] |= rshift(lhs: carry, rhs: 4)
            ib += 1
            carry = 0xF & carry
            if carry == 0 && ia == (la - 1) { return b }
            b.insert((carry) << 4, at: ib)

            while true {
                ia += 1
                if ia >= la { return b }
                if a2b[ascii[ia..<ia + 1]] != nil { break }
            }
            carry = Int32(a2b[ascii[ia..<ia + 1]] ?? 0)
            b[ib] |= rshift(lhs: carry, rhs: 2)
            ib += 1
            carry = 3 & carry
            if carry == 0 && ia == (la - 1) { return b }
            b.insert(carry << 6, at: ib)

            while true {
                ia += 1
                if ia >= la { return b }
                if a2b[ascii[ia..<ia + 1]] != nil { break }
            }
            b[ib] |= Int32(a2b[ascii[ia..<ia + 1]] ?? 0)
            ib += 1
        }

        return b
    }

    static func ascii2binary(ascii: String) -> [Int32] {
        bytes2blocks(bytes: ascii2bytes(ascii: ascii))
    }

    static func tea_code(value v: [Int32], key k: [Int32]) -> [Int32] {
        var v0 = v[safe: 0] ?? 0
        var v1 = v[safe: 1] ?? 0
        var sum: Int32 = 0

        for _ in 0...31 {
            v0 &+= (((v1 << 4) ^ rshift(lhs: v1, rhs: 5)) &+ v1) ^ (sum &+ (k[safe: Int(sum & 3)] ?? 0))
            v0 = v0 | 0
            sum &-= 1_640_531_527
            sum = sum | 0
            v1 &+= (((v0 << 4) ^ rshift(lhs: v0, rhs: 5)) &+ v0) ^ (sum &+ (k[safe: Int(rshift(lhs: sum, rhs: 11)) & 3] ?? 0))
            v1 = v1 | 0
        }

        return [v0, v1]
    }

    static func tea_decode(value v: [Int32], key k: [Int32]) -> [Int32] {
        var v0 = v[safe: 0] ?? 0
        var v1 = v[safe: 1] ?? 0
        var sum: Int32 = -957_401_312

        for _ in 0...31 {
            v1 &-= (((v0 << 4) ^ rshift(lhs: v0, rhs: 5)) &+ v0) ^ (sum &+ (k[safe: Int(rshift(lhs: sum, rhs: 11)) & 3] ?? 0))
            v1 = v1 | 0
            sum &+= 1_640_531_527
            sum = sum | 0
            v0 &-= (((v1 << 4) ^ rshift(lhs: v1, rhs: 5)) &+ v1) ^ (sum &+ (k[safe: Int(sum & 3)] ?? 0))
            v0 = v0 | 0
        }

        return [v0, v1]
    }

    static func decrypt(ascii: String, keystr: String) -> String {
        let key = binarydigest(ascii: keystr)
        let cblocks = ascii2binary(ascii: ascii)
        var icbl = 0
        var lastc: [Int32] = [0x6162_6364, 0x6263_6465]

        var v: [Int32] = []
        var c: [Int32] = [0, 0]
        var blocks: [Int32] = []

        while icbl < cblocks.count {
            c[0] = cblocks[icbl]
            icbl += 1
            c[1] = cblocks[icbl]
            icbl += 1
            v = xor_blocks(blk1: lastc, blk2: tea_decode(value: c, key: key))
            blocks += v
            lastc[0] = c[0]
            lastc[1] = c[1]
        }

        return bytes2str(chars: unpad(chars: blocks2bytes(blocks: blocks)))
    }
}
