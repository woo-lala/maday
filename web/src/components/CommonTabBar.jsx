import React from 'react';
import './CommonTabBar.css';

export const TabItem = {
    HOME: 'home',
    REPORT: 'report',
    ACTIVITY: 'activity',
    SETTINGS: 'settings'
};

export function CommonTabBar({ selectedTab, onSelect }) {
    return (
        <div className="tab-bar">
            <TabButton
                icon="house.fill"
                label="Home"
                isSelected={selectedTab === TabItem.HOME}
                onClick={() => onSelect(TabItem.HOME)}
            />
            <TabButton
                icon="chart.bar.fill"
                label="Report"
                isSelected={selectedTab === TabItem.REPORT}
                onClick={() => onSelect(TabItem.REPORT)}
            />
            <TabButton
                icon="clock.fill"
                label="Activity"
                isSelected={selectedTab === TabItem.ACTIVITY}
                onClick={() => onSelect(TabItem.ACTIVITY)}
            />
            <TabButton
                icon="gearshape.fill"
                label="Settings"
                isSelected={selectedTab === TabItem.SETTINGS}
                onClick={() => onSelect(TabItem.SETTINGS)}
            />
        </div>
    );
}

function TabButton({ icon, label, isSelected, onClick }) {
    // Note: Using SF Symbols names as placeholders. In a real web app, we'd use SVG icons.
    // For now, I'll use simple text/emoji or basic SVGs if needed. 
    // Let's use simple text/emoji for speed, or better, CSS shapes/SVGs later.
    // I'll use text for now to keep it simple as per plan.

    const iconMap = {
        'house.fill': '🏠',
        'chart.bar.fill': '📊',
        'clock.fill': '🕒',
        'gearshape.fill': '⚙️'
    };

    return (
        <button
            className={`tab-button ${isSelected ? 'selected' : ''}`}
            onClick={onClick}
        >
            <span className="tab-icon">{iconMap[icon]}</span>
            <span className="tab-label">{label}</span>
        </button>
    );
}
