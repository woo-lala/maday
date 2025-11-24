import React from 'react';
import './TaskCard.css';

export function TaskCard({ task, isSelected, isActive, onToggleComplete, onClick }) {
    const formatTime = (time) => {
        const totalSeconds = Math.floor(time);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;

        if (hours > 0) return `${hours}h ${minutes}m`;
        if (minutes > 0) return `${minutes}m ${seconds}s`;
        return `${seconds}s`;
    };

    return (
        <div
            className={`task-card ${isSelected ? 'selected' : ''} ${isActive ? 'active' : ''}`}
            onClick={onClick}
        >
            <div className="task-left">
                <button
                    className="check-button"
                    onClick={(e) => { e.stopPropagation(); onToggleComplete(task.id); }}
                >
                    {task.isCompleted ? '✅' : '⚪️'}
                </button>

                <div className="task-info">
                    <div className={`task-title ${task.isCompleted ? 'completed' : ''}`}>
                        {task.title}
                    </div>
                    <div className="task-tracked">
                        Tracked: {formatTime(task.trackedTime)}
                    </div>
                </div>
            </div>

            <div className="task-tag" style={{ backgroundColor: task.categoryColor }}>
                {task.categoryTitle || task.tag}
            </div>
        </div>
    );
}
