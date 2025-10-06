const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*' } // allow connections from anywhere
});

io.on('connection', socket => {
  console.log('Client connected:', socket.id);

  socket.on('join', room => {
    socket.join(room);
    socket.to(room).emit('peer-joined', { id: socket.id });
  });

  socket.on('signal', ({ room, data }) => {
    socket.to(room).emit('signal', data);
  });

  socket.on('disconnect', () => {});
});

const PORT = process.env.PORT || 3000; // Render assigns PORT automatically
server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
});
