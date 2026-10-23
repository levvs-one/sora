package ext

import "github.com/shirou/gopsutil/v4/process"

func workerMemory(p *process.Process) (uint64, error) {
	memory, err := p.MemoryMaps(true)
	if err != nil {
		return 0, err
	}
	// Writable virtual reservations include Go arenas and are not consumed
	// memory on Linux. Account for both resident and swapped pages instead.
	var bytes uint64
	for _, mapping := range *memory {
		bytes += (mapping.Rss + mapping.Swap) * 1024
	}
	return bytes, nil
}
