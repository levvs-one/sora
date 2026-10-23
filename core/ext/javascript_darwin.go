package ext

import "github.com/shirou/gopsutil/v4/process"

func workerMemory(p *process.Process) (uint64, error) {
	memory, err := p.MemoryInfo()
	if err != nil {
		return 0, err
	}
	return memory.RSS, nil
}
