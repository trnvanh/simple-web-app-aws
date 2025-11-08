const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors({
    origin: ['https://d3jx35gx2lx89p.cloudfront.net', 'http://localhost:5173', 'http://localhost:3000'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

let stats = {
    requests: 0,
    startTime: Date.now(),
    lastRequest: null
};

app.use((req, res, next) => {
    stats.requests++;
    stats.lastRequest = new Date().toISOString();
    next();
});
app.get("/", (req, res) => {
    res.json({ 
        message: "🚀 Simple Web App API",
        version: "1.0.0",
        timestamp: new Date().toISOString()
    });
});

app.get("/hello", (req, res) => {
    res.json({ 
        message: "Hello from AWS ECS Fargate! 🐳",
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get("/health", (req, res) => {
    const uptime = Math.floor((Date.now() - stats.startTime) / 1000);
    res.json({
        status: "healthy",
        uptime: `${uptime}s`,
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || '1.0.0'
    });
});

app.get("/stats", (req, res) => {
    const uptime = Math.floor((Date.now() - stats.startTime) / 1000);
    res.json({
        requests: stats.requests,
        uptime: uptime,
        timestamp: new Date().toLocaleTimeString(),
        lastRequest: stats.lastRequest,
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get("/api/data", (req, res) => {
    const data = {
        users: [
            { id: 1, name: "Alice Johnson", role: "Developer" },
            { id: 2, name: "Bob Smith", role: "Designer" },
            { id: 3, name: "Carol Davis", role: "Manager" }
        ],
        projects: [
            { id: 1, name: "Web App", status: "Active" },
            { id: 2, name: "Mobile App", status: "Planning" },
            { id: 3, name: "API Service", status: "Completed" }
        ],
        metrics: {
            totalUsers: 150,
            activeProjects: 8,
            completedTasks: 342
        }
    };
    
    res.json({
        success: true,
        data,
        timestamp: new Date().toISOString()
    });
});
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Something went wrong!',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
    });
});

app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Route not found',
        path: req.originalUrl,
        method: req.method,
        timestamp: new Date().toISOString()
    });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
});