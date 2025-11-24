import React, { useState } from 'react';
import { CommonTabBar, TabItem } from './components/CommonTabBar';
import { RecordPage } from './pages/RecordPage';
import { ReportPage } from './pages/ReportPage';
import './App.css';

function App() {
    const [selectedTab, setSelectedTab] = useState(TabItem.HOME);

    const renderContent = () => {
        switch (selectedTab) {
            case TabItem.HOME:
                return <RecordPage />;
            case TabItem.REPORT:
                return <ReportPage />;
            case TabItem.ACTIVITY:
                return <RecordPage />; // Reusing RecordPage as per iOS app logic
            case TabItem.SETTINGS:
                return (
                    <div className="placeholder-page">
                        <h1 className="font-title">Settings</h1>
                    </div>
                );
            default:
                return <RecordPage />;
        }
    };

    return (
        <div className="app-container">
            <main className="content">
                {renderContent()}
            </main>
            <CommonTabBar selectedTab={selectedTab} onSelect={setSelectedTab} />
        </div>
    );
}

export default App;
