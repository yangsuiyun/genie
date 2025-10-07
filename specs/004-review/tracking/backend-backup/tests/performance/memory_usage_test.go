package performance

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"backend/tests/unit"
)

// Memory usage thresholds
const (
	MaxMemoryUsage     = 100 * 1024 * 1024 // 100MB in bytes
	BaselineThreshold  = 50 * 1024 * 1024  // 50MB baseline
	MemoryLeakGrowth   = 10 * 1024 * 1024  // 10MB max growth per iteration
	GCPressureLimit    = 50                 // Max GC cycles per second
	MaxGoroutines      = 1000               // Maximum concurrent goroutines
)

// MemorySnapshot captures memory usage at a point in time
type MemorySnapshot struct {
	Timestamp    time.Time
	Alloc        uint64 // Currently allocated bytes
	TotalAlloc   uint64 // Total allocated bytes (cumulative)
	Sys          uint64 // System memory obtained from OS
	Mallocs      uint64 // Number of malloc calls
	Frees        uint64 // Number of free calls
	HeapAlloc    uint64 // Heap allocated bytes
	HeapSys      uint64 // Heap system bytes
	HeapIdle     uint64 // Heap idle bytes
	HeapInuse    uint64 // Heap in-use bytes
	StackInuse   uint64 // Stack in-use bytes
	StackSys     uint64 // Stack system bytes
	NumGC        uint32 // Number of GC cycles
	NumGoroutine int    // Number of goroutines
}

// MemoryProfiler tracks memory usage over time
type MemoryProfiler struct {
	snapshots []MemorySnapshot
	mutex     sync.RWMutex
}

func NewMemoryProfiler() *MemoryProfiler {
	return &MemoryProfiler{
		snapshots: make([]MemorySnapshot, 0),
	}
}

func (mp *MemoryProfiler) TakeSnapshot() MemorySnapshot {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	snapshot := MemorySnapshot{
		Timestamp:    time.Now(),
		Alloc:        m.Alloc,
		TotalAlloc:   m.TotalAlloc,
		Sys:          m.Sys,
		Mallocs:      m.Mallocs,
		Frees:        m.Frees,
		HeapAlloc:    m.HeapAlloc,
		HeapSys:      m.HeapSys,
		HeapIdle:     m.HeapIdle,
		HeapInuse:    m.HeapInuse,
		StackInuse:   m.StackInuse,
		StackSys:     m.StackSys,
		NumGC:        m.NumGC,
		NumGoroutine: runtime.NumGoroutine(),
	}

	mp.mutex.Lock()
	mp.snapshots = append(mp.snapshots, snapshot)
	mp.mutex.Unlock()

	return snapshot
}

func (mp *MemoryProfiler) GetSnapshots() []MemorySnapshot {
	mp.mutex.RLock()
	defer mp.mutex.RUnlock()

	// Return a copy
	snapshots := make([]MemorySnapshot, len(mp.snapshots))
	copy(snapshots, mp.snapshots)
	return snapshots
}

func (mp *MemoryProfiler) AnalyzeMemoryGrowth() (totalGrowth uint64, leakDetected bool) {
	snapshots := mp.GetSnapshots()
	if len(snapshots) < 2 {
		return 0, false
	}

	firstSnapshot := snapshots[0]
	lastSnapshot := snapshots[len(snapshots)-1]

	totalGrowth = lastSnapshot.Alloc - firstSnapshot.Alloc

	// Detect potential memory leaks by checking if memory consistently grows
	leakDetected = false
	if len(snapshots) >= 5 {
		// Check if memory allocation trend is consistently upward
		growthCount := 0
		for i := 1; i < len(snapshots); i++ {
			if snapshots[i].Alloc > snapshots[i-1].Alloc {
				growthCount++
			}
		}

		// If more than 70% of samples show growth, potential leak
		leakThreshold := int(float64(len(snapshots)-1) * 0.7)
		leakDetected = growthCount > leakThreshold
	}

	return totalGrowth, leakDetected
}

func TestBaselineMemoryUsage(t *testing.T) {
	t.Run("Application Baseline Memory", func(t *testing.T) {
		// Force garbage collection before measuring baseline
		runtime.GC()
		runtime.GC() // Call twice to ensure cleanup
		time.Sleep(100 * time.Millisecond)

		profiler := NewMemoryProfiler()
		baseline := profiler.TakeSnapshot()

		// Log baseline memory usage
		t.Logf("Baseline Memory Usage:")
		t.Logf("  Allocated: %d bytes (%.2f MB)", baseline.Alloc, float64(baseline.Alloc)/(1024*1024))
		t.Logf("  System: %d bytes (%.2f MB)", baseline.Sys, float64(baseline.Sys)/(1024*1024))
		t.Logf("  Heap Allocated: %d bytes (%.2f MB)", baseline.HeapAlloc, float64(baseline.HeapAlloc)/(1024*1024))
		t.Logf("  Goroutines: %d", baseline.NumGoroutine)

		// Validate baseline is within reasonable limits
		assert.Less(t, baseline.Alloc, uint64(BaselineThreshold),
			"Baseline memory usage should be < %d MB, got %.2f MB",
			BaselineThreshold/(1024*1024), float64(baseline.Alloc)/(1024*1024))

		assert.Less(t, baseline.NumGoroutine, 100,
			"Baseline goroutine count should be reasonable, got %d", baseline.NumGoroutine)
	})
}

func TestMemoryUsageUnderLoad(t *testing.T) {
	t.Run("Memory Usage During API Operations", func(t *testing.T) {
		profiler := NewMemoryProfiler()

		// Take baseline
		runtime.GC()
		baseline := profiler.TakeSnapshot()

		// Simulate API operations that would typically consume memory
		const numOperations = 1000
		users := make([]*unit.CreateTestUser, 0, numOperations)

		for i := 0; i < numOperations; i++ {
			// Create test data (simulating API request processing)
			user := unit.CreateTestUser()
			task := unit.CreateTestTask(user.ID)
			session := unit.CreateTestPomodoroSession(user.ID, task.ID)

			// Store references to prevent immediate GC
			users = append(users, &user)

			// Take periodic snapshots
			if i%100 == 0 {
				profiler.TakeSnapshot()
			}

			// Simulate processing time
			time.Sleep(time.Microsecond)
		}

		// Take final snapshot
		final := profiler.TakeSnapshot()

		// Analyze memory growth
		memoryGrowth := final.Alloc - baseline.Alloc

		t.Logf("Memory Usage Under Load:")
		t.Logf("  Baseline: %.2f MB", float64(baseline.Alloc)/(1024*1024))
		t.Logf("  Final: %.2f MB", float64(final.Alloc)/(1024*1024))
		t.Logf("  Growth: %.2f MB", float64(memoryGrowth)/(1024*1024))
		t.Logf("  Operations: %d", numOperations)

		// Validate memory usage is within limits
		assert.Less(t, final.Alloc, uint64(MaxMemoryUsage),
			"Memory usage under load should be < %d MB, got %.2f MB",
			MaxMemoryUsage/(1024*1024), float64(final.Alloc)/(1024*1024))

		// Memory growth should be reasonable for the amount of data created
		expectedGrowth := uint64(numOperations * 1024) // Rough estimate: 1KB per operation
		assert.Less(t, memoryGrowth, expectedGrowth*10, // Allow 10x overhead
			"Memory growth seems excessive: %.2f MB for %d operations",
			float64(memoryGrowth)/(1024*1024), numOperations)

		// Clean up to verify memory can be reclaimed
		users = nil
		runtime.GC()
		time.Sleep(100 * time.Millisecond)

		afterGC := profiler.TakeSnapshot()
		t.Logf("  After GC: %.2f MB", float64(afterGC.Alloc)/(1024*1024))
	})

	t.Run("Memory Usage During Concurrent Operations", func(t *testing.T) {
		profiler := NewMemoryProfiler()
		runtime.GC()
		baseline := profiler.TakeSnapshot()

		const numGoroutines = 50
		const operationsPerGoroutine = 100

		var wg sync.WaitGroup

		// Start concurrent operations
		for i := 0; i < numGoroutines; i++ {
			wg.Add(1)
			go func(workerID int) {
				defer wg.Done()

				// Each goroutine performs memory-intensive operations
				for j := 0; j < operationsPerGoroutine; j++ {
					user := unit.CreateTestUser()
					tasks := unit.GenerateTestTasks(user.ID, 10)
					sessions := unit.GenerateTestSessions(user.ID, tasks[0].ID, 5)

					// Simulate some processing
					_ = user
					_ = tasks
					_ = sessions

					// Small delay to prevent overwhelming the system
					time.Sleep(time.Microsecond * 10)
				}
			}(i)
		}

		// Monitor memory during concurrent execution
		done := make(chan bool)
		go func() {
			wg.Wait()
			done <- true
		}()

		// Take snapshots during execution
		monitoring := true
		go func() {
			for monitoring {
				profiler.TakeSnapshot()
				time.Sleep(100 * time.Millisecond)
			}
		}()

		// Wait for completion
		<-done
		monitoring = false

		final := profiler.TakeSnapshot()

		t.Logf("Concurrent Operations Memory Usage:")
		t.Logf("  Baseline: %.2f MB", float64(baseline.Alloc)/(1024*1024))
		t.Logf("  Peak: %.2f MB", float64(final.Alloc)/(1024*1024))
		t.Logf("  Goroutines: %d -> %d", baseline.NumGoroutine, final.NumGoroutine)

		// Validate memory usage
		assert.Less(t, final.Alloc, uint64(MaxMemoryUsage),
			"Concurrent operations memory usage should be < %d MB, got %.2f MB",
			MaxMemoryUsage/(1024*1024), float64(final.Alloc)/(1024*1024))

		// Goroutine count should return to reasonable levels
		runtime.GC()
		time.Sleep(200 * time.Millisecond)
		afterCleanup := profiler.TakeSnapshot()

		assert.Less(t, afterCleanup.NumGoroutine, baseline.NumGoroutine+20,
			"Goroutine count should return to near baseline after cleanup")
	})
}

func TestMemoryLeakDetection(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping memory leak test in short mode")
	}

	t.Run("Long Running Memory Leak Detection", func(t *testing.T) {
		profiler := NewMemoryProfiler()

		// Force initial cleanup
		runtime.GC()
		runtime.GC()
		time.Sleep(100 * time.Millisecond)

		baseline := profiler.TakeSnapshot()

		// Simulate long-running operations
		const iterations = 100
		const operationsPerIteration = 50

		for iteration := 0; iteration < iterations; iteration++ {
			// Simulate request processing that could leak memory
			for op := 0; op < operationsPerIteration; op++ {
				user := unit.CreateTestUser()
				task := unit.CreateTestTask(user.ID)
				session := unit.CreateTestPomodoroSession(user.ID, task.ID)

				// Simulate some processing that should be cleaned up
				processData(user, task, session)
			}

			// Take snapshot every 10 iterations
			if iteration%10 == 0 {
				runtime.GC() // Force GC periodically
				snapshot := profiler.TakeSnapshot()

				t.Logf("Iteration %d: Memory %.2f MB, Goroutines %d",
					iteration, float64(snapshot.Alloc)/(1024*1024), snapshot.NumGoroutine)
			}

			// Small delay to allow cleanup
			time.Sleep(10 * time.Millisecond)
		}

		// Final analysis
		totalGrowth, leakDetected := profiler.AnalyzeMemoryGrowth()

		t.Logf("Memory Leak Analysis:")
		t.Logf("  Total Growth: %.2f MB", float64(totalGrowth)/(1024*1024))
		t.Logf("  Leak Detected: %v", leakDetected)

		// Validate no significant memory leaks
		assert.False(t, leakDetected,
			"Memory leak detected during long-running operations")

		assert.Less(t, totalGrowth, uint64(MemoryLeakGrowth),
			"Total memory growth should be < %d MB, got %.2f MB",
			MemoryLeakGrowth/(1024*1024), float64(totalGrowth)/(1024*1024))

		// Final cleanup verification
		runtime.GC()
		runtime.GC()
		time.Sleep(200 * time.Millisecond)

		final := profiler.TakeSnapshot()
		finalGrowth := final.Alloc - baseline.Alloc

		t.Logf("  After Final GC: %.2f MB (growth: %.2f MB)",
			float64(final.Alloc)/(1024*1024),
			float64(finalGrowth)/(1024*1024))

		assert.Less(t, finalGrowth, uint64(MemoryLeakGrowth/2),
			"Memory should be mostly reclaimed after GC")
	})
}

func TestGarbageCollectionPressure(t *testing.T) {
	t.Run("GC Pressure Under Load", func(t *testing.T) {
		runtime.GC()

		var initialStats runtime.MemStats
		runtime.ReadMemStats(&initialStats)
		initialGCCount := initialStats.NumGC

		startTime := time.Now()

		// Generate GC pressure
		const duration = 5 * time.Second
		const goroutines = 20

		ctx, cancel := context.WithTimeout(context.Background(), duration)
		defer cancel()

		var wg sync.WaitGroup

		for i := 0; i < goroutines; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				generateGCPressure(ctx)
			}()
		}

		wg.Wait()

		var finalStats runtime.MemStats
		runtime.ReadMemStats(&finalStats)

		elapsedTime := time.Since(startTime)
		gcCycles := finalStats.NumGC - initialGCCount
		gcRate := float64(gcCycles) / elapsedTime.Seconds()

		t.Logf("GC Pressure Test Results:")
		t.Logf("  Duration: %v", elapsedTime)
		t.Logf("  GC Cycles: %d", gcCycles)
		t.Logf("  GC Rate: %.2f cycles/second", gcRate)
		t.Logf("  Total Alloc: %.2f MB", float64(finalStats.TotalAlloc)/(1024*1024))
		t.Logf("  Current Alloc: %.2f MB", float64(finalStats.Alloc)/(1024*1024))

		// Validate GC pressure is reasonable
		assert.Less(t, gcRate, float64(GCPressureLimit),
			"GC pressure should be < %d cycles/second, got %.2f", GCPressureLimit, gcRate)

		// Memory should still be within limits after GC pressure
		assert.Less(t, finalStats.Alloc, uint64(MaxMemoryUsage),
			"Memory usage after GC pressure should be < %d MB, got %.2f MB",
			MaxMemoryUsage/(1024*1024), float64(finalStats.Alloc)/(1024*1024))
	})
}

func TestGoroutineLeaks(t *testing.T) {
	t.Run("Goroutine Leak Detection", func(t *testing.T) {
		runtime.GC()
		baselineGoroutines := runtime.NumGoroutine()

		// Simulate operations that create goroutines
		const numOperations = 100
		var wg sync.WaitGroup

		for i := 0; i < numOperations; i++ {
			wg.Add(1)
			go func(operationID int) {
				defer wg.Done()

				// Simulate work that creates temporary goroutines
				var innerWG sync.WaitGroup
				for j := 0; j < 5; j++ {
					innerWG.Add(1)
					go func() {
						defer innerWG.Done()
						// Simulate short-lived work
						time.Sleep(time.Millisecond)
					}()
				}
				innerWG.Wait()
			}(i)
		}

		wg.Wait()

		// Allow time for goroutines to clean up
		time.Sleep(100 * time.Millisecond)
		runtime.GC()
		time.Sleep(100 * time.Millisecond)

		finalGoroutines := runtime.NumGoroutine()
		goroutineGrowth := finalGoroutines - baselineGoroutines

		t.Logf("Goroutine Leak Test:")
		t.Logf("  Baseline: %d goroutines", baselineGoroutines)
		t.Logf("  Final: %d goroutines", finalGoroutines)
		t.Logf("  Growth: %d goroutines", goroutineGrowth)

		// Validate no significant goroutine leaks
		assert.Less(t, goroutineGrowth, 20,
			"Goroutine growth should be minimal, got %d new goroutines", goroutineGrowth)

		assert.Less(t, finalGoroutines, MaxGoroutines,
			"Total goroutines should be < %d, got %d", MaxGoroutines, finalGoroutines)
	})
}

func TestMemoryPoolEfficiency(t *testing.T) {
	t.Run("Memory Pool and Reuse Efficiency", func(t *testing.T) {
		profiler := NewMemoryProfiler()
		runtime.GC()
		baseline := profiler.TakeSnapshot()

		// Test object reuse patterns
		const poolSize = 1000
		const iterations = 10

		// Simulate object pooling behavior
		objectPool := make(chan interface{}, poolSize)

		// Fill pool
		for i := 0; i < poolSize; i++ {
			user := unit.CreateTestUser()
			objectPool <- user
		}

		afterPoolCreation := profiler.TakeSnapshot()

		// Test pool reuse efficiency
		for iteration := 0; iteration < iterations; iteration++ {
			for i := 0; i < poolSize; i++ {
				// Get object from pool
				obj := <-objectPool

				// Use object (simulate processing)
				_ = obj

				// Return to pool
				objectPool <- obj
			}

			if iteration%3 == 0 {
				profiler.TakeSnapshot()
			}
		}

		final := profiler.TakeSnapshot()

		poolCreationMemory := afterPoolCreation.Alloc - baseline.Alloc
		totalGrowth := final.Alloc - baseline.Alloc

		t.Logf("Memory Pool Efficiency:")
		t.Logf("  Pool Creation: %.2f MB", float64(poolCreationMemory)/(1024*1024))
		t.Logf("  Total Growth: %.2f MB", float64(totalGrowth)/(1024*1024))
		t.Logf("  Efficiency Ratio: %.2f", float64(poolCreationMemory)/float64(totalGrowth))

		// Pool should prevent excessive memory allocation
		efficiencyRatio := float64(poolCreationMemory) / float64(totalGrowth)
		assert.Greater(t, efficiencyRatio, 0.8,
			"Pool should prevent most additional allocations, efficiency ratio: %.2f", efficiencyRatio)

		// Total memory usage should still be reasonable
		assert.Less(t, final.Alloc, uint64(MaxMemoryUsage),
			"Total memory with pool should be < %d MB, got %.2f MB",
			MaxMemoryUsage/(1024*1024), float64(final.Alloc)/(1024*1024))
	})
}

// Helper functions

func processData(user *models.User, task *models.Task, session *models.PomodoroSession) {
	// Simulate data processing that might cause memory leaks if not properly handled

	// Create some temporary data structures
	tempMap := make(map[string]interface{})
	tempMap["user"] = user.ID.String()
	tempMap["task"] = task.Title
	tempMap["session"] = session.ID.String()

	// Simulate processing
	for i := 0; i < 100; i++ {
		tempMap[fmt.Sprintf("key_%d", i)] = fmt.Sprintf("value_%d", i)
	}

	// Cleanup should happen automatically when function returns
	tempMap = nil
}

func generateGCPressure(ctx context.Context) {
	// Generate lots of short-lived allocations to pressure the GC
	for {
		select {
		case <-ctx.Done():
			return
		default:
			// Create temporary objects that will be quickly collected
			data := make([]byte, 1024*10) // 10KB allocations
			_ = data

			// Create some temporary maps and slices
			tempMap := make(map[int]string)
			for i := 0; i < 100; i++ {
				tempMap[i] = fmt.Sprintf("temp_value_%d", i)
			}

			tempSlice := make([]string, 100)
			for i := range tempSlice {
				tempSlice[i] = fmt.Sprintf("slice_item_%d", i)
			}

			// Let them be collected
			tempMap = nil
			tempSlice = nil

			// Small delay to prevent overwhelming the system
			time.Sleep(time.Microsecond * 100)
		}
	}
}