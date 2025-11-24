import React, { useState, useEffect, useRef } from 'react';
import { api } from '../services/api';
import { TaskCard } from '../components/TaskCard';
import './RecordPage.css';

export function RecordPage() {
    const [tasks, setTasks] = useState([]);
    const [selectedTaskId, setSelectedTaskId] = useState(null);
    const [activeTaskId, setActiveTaskId] = useState(null);
    const [isTimerRunning, setIsTimerRunning] = useState(false);
    const [sessionElapsed, setSessionElapsed] = useState(0);

    const timerRef = useRef(null);

    useEffect(() => {
        loadTasks();
    }, []);

    useEffect(() => {
        if (isTimerRunning) {
            timerRef.current = setInterval(() => {
                setSessionElapsed(prev => prev + 1);
                if (activeTaskId) {
                    setTasks(prevTasks => prevTasks.map(t =>
                        t.id === activeTaskId
                            ? { ...t, trackedTime: t.trackedTime + 1 }
                            : t
                    ));
                }
            }, 1000);
        } else {
            clearInterval(timerRef.current);
        }
        return () => clearInterval(timerRef.current);
    }, [isTimerRunning, activeTaskId]);

    const loadTasks = async () => {
        const data = await api.getTasks();
        setTasks(data);
        if (data.length > 0) setSelectedTaskId(data[0].id);
    };

    const handleTaskClick = (id) => {
        if (activeTaskId && activeTaskId !== id) {
            stopTimer();
        }
        setSelectedTaskId(id);
    };

    const toggleComplete = (id) => {
        setTasks(tasks.map(t => t.id === id ? { ...t, isCompleted: !t.isCompleted } : t));
    };

    const startTimer = async () => {
        if (!selectedTaskId || isTimerRunning) return;

        if (activeTaskId !== selectedTaskId) {
            setActiveTaskId(selectedTaskId);
            setSessionElapsed(0);
        }

        await api.startTimer(selectedTaskId);
        setIsTimerRunning(true);
    };

    const pauseTimer = () => {
        setIsTimerRunning(false);
    };

    const stopTimer = async () => {
        if (!activeTaskId && sessionElapsed === 0) return;

        const endTime = new Date();
        // Calculate start time based on elapsed duration
        const startTime = new Date(endTime.getTime() - sessionElapsed * 1000);

        await api.stopTimer(
            activeTaskId,
            sessionElapsed,
            startTime.toISOString(),
            endTime.toISOString()
        );

        setIsTimerRunning(false);
        setSessionElapsed(0);
        setActiveTaskId(null);
    };

    const formatTimer = (seconds) => {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    };

    const totalTime = tasks.reduce((acc, t) => acc + t.trackedTime, 0);

    return (
        <div className="page-container">
            <header className="app-bar">
                <h1 className="font-large-title">Today</h1>
            </header>

            <section className="tasks-section">
                <div className="section-header">
                    <h2 className="font-headline">My Tasks</h2>
                    <button className="add-btn">+</button>
                </div>

                <div className="tasks-list">
                    {tasks.map(task => (
                        <TaskCard
                            key={task.id}
                            task={task}
                            isSelected={selectedTaskId === task.id}
                            isActive={activeTaskId === task.id}
                            onToggleComplete={toggleComplete}
                            onClick={() => handleTaskClick(task.id)}
                        />
                    ))}
                </div>
            </section>

            <section className="timer-section">
                <div className="timer-display font-timer">
                    {formatTimer(sessionElapsed)}
                </div>
                <div className="total-time font-body text-secondary">
                    Total Time Today: {Math.floor(totalTime / 3600)}h {Math.floor((totalTime % 3600) / 60)}m
                </div>
            </section>

            <section className="controls-section">
                <button
                    className="control-btn primary"
                    disabled={!selectedTaskId || isTimerRunning}
                    onClick={startTimer}
                >
                    ▶ Start
                </button>
                <button
                    className="control-btn neutral"
                    disabled={!isTimerRunning}
                    onClick={pauseTimer}
                >
                    ⏸ Pause
                </button>
                <button
                    className="control-btn destructive"
                    disabled={!activeTaskId && sessionElapsed === 0}
                    onClick={stopTimer}
                >
                    ⏹ Stop
                </button>
            </section>
        </div>
    );
}
