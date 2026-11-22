
import std.prelude;
import std.container.list;

/// BitSet module namespace.
struct std::bitset {}

/// A growable bitset backed by 32-bit words. Bits are indexed from zero.
/// Capacity grows on demand via `bitset_resize`; setting or testing an index
/// outside `count` is rejected.
struct BitSet {
    List<uint> words;
    int count;
}

BitSet make_bitset(int bit_count) {
    BitSet result;
    result.count = 0;
    if (bit_count > 0) {
        result.count = bit_count;
    }
    int word_count = (result.count + 31) / 32;
    for (int index = 0; index < word_count; index = index + 1) {
        result.words.push_back(0);
    }
    return result;
}

int bitset_size(BitSet* set) {
    if (set == nullptr) {
        return 0;
    }
    return set.count;
}

int bitset_capacity(BitSet* set) {
    if (set == nullptr) {
        return 0;
    }
    return set.words.length * 32;
}

uint bitset_mask(int index) {
    uint mask = 1;
    return mask << (index % 32);
}

/// True when `index` is in range and set.
bool bitset_test(BitSet* set, int index) {
    if (set == nullptr || index < 0 || index >= set.count) {
        return false;
    }
    int word = index / 32;
    if (word < 0 || word >= set.words.length) {
        return false;
    }
    return (set.words[word] & bitset_mask(index)) != 0;
}

/// Set a bit. Returns false when the index is outside the current size.
bool bitset_set(BitSet* set, int index) {
    if (set == nullptr || index < 0 || index >= set.count) {
        return false;
    }
    int word = index / 32;
    if (word < 0 || word >= set.words.length) {
        return false;
    }
    set.words[word] = set.words[word] | bitset_mask(index);
    return true;
}

/// Clear a bit. Returns false when the index is outside the current size.
bool bitset_reset(BitSet* set, int index) {
    if (set == nullptr || index < 0 || index >= set.count) {
        return false;
    }
    int word = index / 32;
    if (word < 0 || word >= set.words.length) {
        return false;
    }
    set.words[word] = set.words[word] & (~bitset_mask(index));
    return true;
}

/// Flip a bit. Returns its new value, or false for an out-of-range index.
bool bitset_toggle(BitSet* set, int index) {
    if (set == nullptr || index < 0 || index >= set.count) {
        return false;
    }
    int word = index / 32;
    if (word < 0 || word >= set.words.length) {
        return false;
    }
    set.words[word] = set.words[word] ^ bitset_mask(index);
    return bitset_test(set, index);
}

/// Set every bit in the current size.
void bitset_set_all(BitSet* set) {
    if (set == nullptr) {
        return;
    }
    int word_count = (set.count + 31) / 32;
    for (int index = 0; index < word_count; index = index + 1) {
        set.words[index] = 4294967295;
    }
}

/// Clear every bit while keeping the allocated words.
void bitset_clear_all(BitSet* set) {
    if (set == nullptr) {
        return;
    }
    int word_count = (set.count + 31) / 32;
    for (int index = 0; index < word_count; index = index + 1) {
        set.words[index] = 0;
    }
}

/// Number of set bits.
int bitset_count(BitSet* set) {
    if (set == nullptr) {
        return 0;
    }
    int total = 0;
    for (int index = 0; index < set.count; index = index + 1) {
        if (bitset_test(set, index)) {
            total = total + 1;
        }
    }
    return total;
}

bool bitset_any(BitSet* set) => bitset_count(set) > 0;

bool bitset_none(BitSet* set) => bitset_count(set) == 0;

/// True when every bit in the current size is set. An empty bitset is all-set.
bool bitset_all(BitSet* set) {
    if (set == nullptr || set.count == 0) {
        return true;
    }
    return bitset_count(set) == set.count;
}

/// Index of the lowest set bit, or -1 when none is set.
int bitset_first_set(BitSet* set) {
    if (set == nullptr) {
        return -1;
    }
    for (int index = 0; index < set.count; index = index + 1) {
        if (bitset_test(set, index)) {
            return index;
        }
    }
    return -1;
}

/// Change the number of addressable bits. Growing keeps existing bits and
/// clears the newly exposed ones; shrinking preserves the stored words so a
/// later grow starts clean.
void bitset_resize(BitSet* set, int bit_count) {
    if (set == nullptr) {
        return;
    }
    int target = bit_count;
    if (target < 0) {
        target = 0;
    }
    int old_count = set.count;
    int word_count = (target + 31) / 32;
    while (set.words.length < word_count) {
        set.words.push_back(0);
    }
    set.count = target;
    if (target > old_count) {
        for (int index = old_count; index < target; index = index + 1) {
            bitset_reset(set, index);
        }
    }
}

/// Render the bitset as '0' and '1' characters, most significant bit first.
/// The output is NUL-terminated when it fits. Returns the number of characters
/// written, or -1 for a null argument or a buffer smaller than size + 1.
int bitset_to_chars(BitSet* set, char* output, int output_capacity) {
    if (set == nullptr || output == nullptr || output_capacity <= 0) {
        return -1;
    }
    if (set.count + 1 > output_capacity) {
        return -1;
    }
    int target = 0;
    for (int index = set.count - 1; index >= 0; index = index - 1) {
        if (bitset_test(set, index)) {
            output[target] = '1';
        } else {
            output[target] = '0';
        }
        target = target + 1;
    }
    output[target] = '\0';
    return target;
}
