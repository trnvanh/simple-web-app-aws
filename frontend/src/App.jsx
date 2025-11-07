import { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState("Loading...");
  const [stats, setStats] = useState(null);
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const API_BASE_URL = 'https://simple-web-app-alb-32739058.us-east-1.elb.amazonaws.com';

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const helloResponse = await fetch(`${API_BASE_URL}/hello`);
      const helloData = await helloResponse.json();
      setMessage(helloData.message);

      const statsResponse = await fetch(`${API_BASE_URL}/stats`);
      const statsData = await statsResponse.json();
      setStats(statsData);

      const healthResponse = await fetch(`${API_BASE_URL}/health`);
      const healthData = await healthResponse.json();
      setHealth(healthData);

    } catch (err) {
      console.error('Failed to fetch data:', err);
      setError('Could not reach backend API');
      setMessage('Backend unavailable');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const getResultBoxClass = () => {
    if (loading) return 'result-box loading';
    if (error) return 'result-box error';
    return 'result-box success';
  };

  return (
    <div className="container">
      <h1>🚀 Simple Web App</h1>
      <p>A modern React frontend with Node.js backend, deployed on AWS</p>

      <div className={getResultBoxClass()}>
        {loading ? 'Loading...' : (error || message)}
      </div>

      <button className="refresh-btn" onClick={fetchData} disabled={loading}>
        {loading ? 'Refreshing...' : 'Refresh Data'}
      </button>

      {stats && (
        <div className="stats-grid">
          <div className="stat-card">
            <span className="stat-value">{stats.requests}</span>
            <div className="stat-label">API Requests</div>
          </div>
          <div className="stat-card">
            <span className="stat-value">{stats.uptime}</span>
            <div className="stat-label">Uptime (seconds)</div>
          </div>
          <div className="stat-card">
            <span className="stat-value">{stats.timestamp}</span>
            <div className="stat-label">Last Updated</div>
          </div>
        </div>
      )}

      {health && (
        <div className="stats-grid" style={{ marginTop: '1rem' }}>
          <div className="stat-card" style={{ background: health.status === 'healthy' ? 'linear-gradient(135deg, #4facfe, #00f2fe)' : 'linear-gradient(135deg, #ff6b6b, #ee5a52)' }}>
            <span className="stat-value">{health.status}</span>
            <div className="stat-label">System Status</div>
          </div>
          <div className="stat-card">
            <span className="stat-value">{health.environment}</span>
            <div className="stat-label">Environment</div>
          </div>
        </div>
      )}

      <div style={{ marginTop: '2rem', padding: '1rem', background: 'rgba(102, 126, 234, 0.1)', borderRadius: '10px' }}>
        <h3 style={{ color: '#667eea', marginBottom: '0.5rem' }}>Infrastructure</h3>
        <p style={{ fontSize: '0.9rem', color: '#7f8c8d' }}>
          Frontend: React + Vite → AWS S3 + CloudFront<br/>
          Backend: Node.js + Express → AWS ECS Fargate<br/>
          Infrastructure: Terraform (IaC)
        </p>
      </div>
    </div>
  );
}

export default App;
