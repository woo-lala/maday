// Mock Data matching iOS app
const TASKS = [
    { id: '1', title: "Work on Project Dayflow", tag: "Work", detail: "Finalize sprint backlog and sync with design", categoryTitle: "Work", categoryColor: "var(--color-work)", trackedTime: 0, isCompleted: false },
    { id: '2', title: "Read Atomic Habits", tag: "Personal", detail: "Read 20 pages before bed", categoryTitle: "Personal", categoryColor: "var(--color-personal)", trackedTime: 0, isCompleted: false },
    { id: '3', title: "30 min HIIT Session", tag: "Fitness", detail: "Power session from the Daily Burn plan", categoryTitle: "Fitness", categoryColor: "var(--color-fitness)", trackedTime: 0, isCompleted: false },
    { id: '4', title: "Review YouTube Analytics", tag: "Work", detail: "Check watch time and retention charts", categoryTitle: "Work", categoryColor: "var(--color-work)", trackedTime: 0, isCompleted: false }
];

const WEEKLY_DATA = {
    timeline: [
        { day: "Mon", blocks: [{ category: "Work", startRatio: 0.25, durationRatio: 0.25 }, { category: "Study", startRatio: 0.6, durationRatio: 0.15 }] },
        { day: "Tue", blocks: [{ category: "Work", startRatio: 0.2, durationRatio: 0.3 }, { category: "Personal", startRatio: 0.65, durationRatio: 0.1 }] },
        { day: "Wed", blocks: [{ category: "Work", startRatio: 0.3, durationRatio: 0.25 }, { category: "Leisure", startRatio: 0.7, durationRatio: 0.1 }] },
        { day: "Thu", blocks: [{ category: "Work", startRatio: 0.2, durationRatio: 0.35 }] },
        { day: "Fri", blocks: [{ category: "Work", startRatio: 0.25, durationRatio: 0.3 }, { category: "Health", startRatio: 0.65, durationRatio: 0.1 }] },
        { day: "Sat", blocks: [{ category: "Leisure", startRatio: 0.4, durationRatio: 0.25 }] },
        { day: "Sun", blocks: [{ category: "Personal", startRatio: 0.3, durationRatio: 0.2 }] }
    ],
    categoryRatio: [
        { category: "Work", percentage: 35, color: "var(--color-work)" },
        { category: "Study", percentage: 20, color: "var(--color-learning)" },
        { category: "Leisure", percentage: 18, color: "var(--color-youtube)" },
        { category: "Health", percentage: 15, color: "var(--color-fitness)" },
        { category: "Personal", percentage: 12, color: "var(--color-personal)" }
    ],
    distribution: [
        { day: "Mon", totalHours: 3.5, fullDate: "Monday, Aug 14" },
        { day: "Tue", totalHours: 4.0, fullDate: "Tuesday, Aug 15" },
        { day: "Wed", totalHours: 2.0, fullDate: "Wednesday, Aug 16" },
        { day: "Thu", totalHours: 5.5, fullDate: "Thursday, Aug 17" },
        { day: "Fri", totalHours: 3.0, fullDate: "Friday, Aug 18" },
        { day: "Sat", totalHours: 4.5, fullDate: "Saturday, Aug 19" },
        { day: "Sun", totalHours: 2.5, fullDate: "Sunday, Aug 20" }
    ],
    dailyTasks: [
        { day: "Mon", title: "Project Planning", duration: "1h 20m" },
        { day: "Mon", title: "Client Meeting", duration: "0h 50m" },
        { day: "Mon", title: "Design Review", duration: "0h 40m" },
        // ... add more if needed
    ]
};

// Simulate API delay
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

export const api = {
    getTasks: async () => {
        await delay(300);
        return [...TASKS];
    },

    createTask: async (task) => {
        console.log('[API] Create task:', task);
        await delay(300);
        const newTask = { ...task, id: Date.now().toString() };
        TASKS.push(newTask);
        return newTask;
    },

    updateTask: async (task) => {
        console.log('[API] Update task:', task);
        await delay(300);
        const index = TASKS.findIndex(t => t.id === task.id);
        if (index !== -1) {
            TASKS[index] = task;
            return task;
        }
        throw new Error('Task not found');
    },

    updateTaskOrder: async (taskIds) => {
        console.log('[API] Update task order:', taskIds);
        await delay(300);
        // In a real app, we would reorder TASKS array based on taskIds
        return { success: true };
    },

    createCategory: async (category) => {
        console.log('[API] Create category:', category);
        await delay(300);
        return { ...category, id: Date.now().toString() };
    },

    updateCategory: async (category) => {
        console.log('[API] Update category:', category);
        await delay(300);
        return category;
    },

    getWeeklyReport: async () => {
        await delay(300);
        return WEEKLY_DATA;
    },

    // Simulate starting timer (server would record start time)
    startTimer: async (taskId) => {
        console.log(`[API] Start timer for task ${taskId}`);
        return { success: true, startTime: new Date().toISOString() };
    },

    // Simulate stopping timer (server would calculate duration)
    stopTimer: async (taskId, duration, startTime, endTime) => {
        console.log(`[API] Stop timer for task ${taskId}, duration: ${duration}s`);

        // Enhanced Logic: Record specific times if session > 5 mins (300 seconds)
        if (duration > 300) {
            console.log(`[API] Long session (>5m). Recording time range: ${startTime} - ${endTime}`);
            // In a real backend, we would save this session record
        }

        return { success: true };
    }
};
