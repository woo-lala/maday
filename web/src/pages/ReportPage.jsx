import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import './ReportPage.css';

export function ReportPage() {
    const [data, setData] = useState(null);
    const [selectedDay, setSelectedDay] = useState("Mon");

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        const reportData = await api.getWeeklyReport();
        setData(reportData);
    };

    if (!data) return <div className="loading">Loading...</div>;

    const selectedDayData = data.distribution.find(d => d.day === selectedDay);
    const dailyTasks = data.dailyTasks.filter(t => t.day === selectedDay);

    return (
        <div className="page-container report-page">
            <header className="report-header">
                <h1 className="font-large-title">Weekly Report</h1>
                <div className="date-range-selector">
                    <button className="nav-btn">‹</button>
                    <span className="font-headline">Aug 14 - Aug 20</span>
                    <button className="nav-btn">›</button>
                </div>
            </header>

            <section className="chart-section">
                <h2 className="font-headline section-title">Weekly Performance Overview</h2>
                <div className="timeline-chart">
                    <div className="y-axis">
                        {['00:00', '06:00', '12:00', '18:00', '24:00'].map((label, i) => (
                            <div key={i} className="y-label" style={{ top: `${i * 25}%` }}>
                                <span>{label}</span>
                                <div className="grid-line"></div>
                            </div>
                        ))}
                    </div>
                    <div className="bars-container">
                        {data.timeline.map(day => (
                            <div key={day.day} className="day-column">
                                <div className="day-bar">
                                    {day.blocks.map((block, i) => (
                                        <div
                                            key={i}
                                            className="time-block"
                                            style={{
                                                top: `${block.startRatio * 100}%`,
                                                height: `${block.durationRatio * 100}%`,
                                                backgroundColor: `var(--color-${block.category.toLowerCase()})`
                                            }}
                                        />
                                    ))}
                                </div>
                                <span className="x-label font-caption">{day.day}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            <section className="chart-section">
                <h2 className="font-headline section-title">Weekly Category Ratio</h2>
                <div className="ratio-container">
                    <div className="donut-chart">
                        {/* Simple CSS Conic Gradient for Donut Chart */}
                        <div
                            className="donut"
                            style={{
                                background: `conic-gradient(
                  ${data.categoryRatio.map((item, i, arr) => {
                                    const prev = arr.slice(0, i).reduce((acc, curr) => acc + curr.percentage, 0);
                                    return `${item.color} ${prev}%, ${item.color} ${prev + item.percentage}%`;
                                }).join(', ')}
                )`
                            }}
                        >
                            <div className="donut-hole"></div>
                        </div>
                    </div>
                    <div className="legend">
                        {data.categoryRatio.map(item => (
                            <div key={item.category} className="legend-item">
                                <div className="dot" style={{ backgroundColor: item.color }}></div>
                                <span className="font-body">{item.category} • {item.percentage}%</span>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            <section className="chart-section">
                <h2 className="font-headline section-title">Weekly Distribution</h2>
                <p className="font-caption text-secondary">Click a day to view daily details.</p>
                <div className="distribution-chart">
                    {data.distribution.map(item => {
                        const isSelected = selectedDay === item.day;
                        return (
                            <div
                                key={item.day}
                                className="dist-column"
                                onClick={() => setSelectedDay(item.day)}
                            >
                                <div
                                    className={`dist-bar ${isSelected ? 'selected' : ''}`}
                                    style={{ height: `${item.totalHours * 20}px` }}
                                ></div>
                                <span className="x-label font-caption">{item.day}</span>
                            </div>
                        );
                    })}
                </div>
            </section>

            {selectedDayData && (
                <section className="daily-details">
                    <div className="details-header">
                        <h3 className="font-headline">{selectedDayData.fullDate}</h3>
                        <span className="font-body text-secondary">
                            {Math.floor(selectedDayData.totalHours)}h {Math.round((selectedDayData.totalHours % 1) * 60)}m
                        </span>
                    </div>
                    <div className="daily-tasks">
                        {dailyTasks.map((task, i) => (
                            <div key={i} className="daily-task-item">
                                <span className="font-body">{task.title}</span>
                                <span className="duration-badge font-caption">{task.duration}</span>
                            </div>
                        ))}
                    </div>
                </section>
            )}
        </div>
    );
}
