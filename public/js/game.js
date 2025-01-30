document.addEventListener("DOMContentLoaded", () => {
    const editableElements = document.querySelectorAll(".editable"); 

    // Initial leaderboard load
    const gameId = document.querySelector('.points-cell').getAttribute('game-id');
    fetchLeaderboard(gameId);

    // DBLCLICK ON SPAN TURNS INTO INPUT
    editableElements.forEach((element) => {
      element.addEventListener("dblclick", (event) => {
        const span = event.target;
        const player = span.dataset.player;
        const round = span.dataset.round;
        const action = span.dataset.action;
        const value = span.innerText;
        const gameId = span.dataset.gameid;
        
        // Check if this is a registerTricks action and if it's not editable yet
        if (action === 'registerTricks' && span.dataset.editable !== 'true') {
          console.log('Cannot register tricks until all players have asked for tricks');
          return;
        }
  
        const input = document.createElement("input");
        input.type = "number";
        input.value = value === "-" ? "" : value;
        input.dataset.player = player;
        input.dataset.round = round;
        input.dataset.action = action;
        input.dataset.gameid = gameId;
        
        let isHandled = false;
        
        const handleChange = (event) => {
          if (isHandled) return;
          isHandled = true;
          
          const value = input.value;
          span.innerText = value === "" ? "-" : value;
          span.style.display = "inline";
          
          // Remove event listeners before removing the input
          input.removeEventListener("blur", handleChange);
          input.removeEventListener("keypress", handleKeyPress);
          input.remove();
          
          // Update game state
          updateGameState(action, player, value, gameId);
          fetchLeaderboard(gameId);
        };
        
        const handleKeyPress = (event) => {
          if (event.key === 'Enter') {
            event.preventDefault();
            handleChange(event);
          }
        };
  
        input.addEventListener("blur", handleChange);
        input.addEventListener("keypress", handleKeyPress);
  
        span.style.display = "none";
        span.parentNode.insertBefore(input, span);
        input.focus();
      });
    });
});

function handleInputChange(event) {
    const input = event.target;
    const player = input.dataset.player;
    const gameId = input.dataset.gameid;
    const action = input.dataset.action;
    const value = input.value;
    const span = input.nextSibling;

    // Update the span and remove input
    span.innerText = value === "" ? "-" : value;
    span.style.display = "inline";
    input.remove();

    // Update game state
    updateGameState(action, player, value, gameId);
    fetchLeaderboard(gameId);
}

function sendGameState(gameState, gameId) {
  console.log('Sending game id', gameId);
  fetch('/api/update_game_state', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ game_state: gameState, game_id: gameId })
  })
  .then(response => response.json())
  .then(updatedGameState => {
    // Update the DOM with the server-returned state
    updateDOMGameState(updatedGameState);
  })
  .catch(error => console.error('Error:', error));
}

function updateGameState(action, player, value, gameId) {
  const gameState = gameStateFromDOM();
  const round = gameState.rounds[gameState.current_round_number];

  if (action === 'askForTricks') {
    round.asked_tricks[player] = parseInt(value, 10);
  } else if (action === 'registerTricks') {
    round.tricks_made[player] = parseInt(value, 10);
  }

  // Update the tricks values immediately in the DOM
  updateTricksInDOM(gameState);
  
  // Send to server and wait for response to update points and forbidden value
  sendGameState(gameState, gameId);
}

function updateTricksInDOM(gameState) {
  const roundNumber = gameState.current_round_number;
  const round = gameState.rounds[roundNumber];
  
  // Update the gameState in the script tag
  document.querySelector('script').innerText = `var gameState = ${JSON.stringify(gameState)};`;

  // Update data-editable attributes for all rounds
  Object.entries(gameState.rounds).forEach(([index, roundData]) => {
    document.querySelectorAll(`[data-action="registerTricks"][data-round="${index}"]`).forEach(span => {
      span.dataset.editable = allPlayersAsked(roundData).toString();
    });
  });

  // Update tricks/cards ratio for all rounds
  Object.entries(gameState.rounds).forEach(([index, roundData]) => {
    // Update ratio
    const ratioCell = document.querySelector(`.game-table tbody tr:nth-child(${parseInt(index) + 1}) .tricks-cards-ratio`);
    if (ratioCell) {
      ratioCell.textContent = `${roundData.total_tricks_asked}/${roundData.amount_of_cards}`;
    }
  });
}

function updateDOMGameState(gameState) {
  // Update the gameState in the script tag
  document.querySelector('script').innerText = `var gameState = ${JSON.stringify(gameState)};`;

  // Update data-editable attributes and tricks/cards ratio for all rounds
  Object.entries(gameState.rounds).forEach(([index, roundData]) => {
    // Update editable status
    document.querySelectorAll(`[data-action="registerTricks"][data-round="${index}"]`).forEach(span => {
      span.dataset.editable = allPlayersAsked(roundData).toString();
    });

    // Update ratio
    const ratioCell = document.querySelector(`.game-table tbody tr:nth-child(${parseInt(index) + 1}) .tricks-cards-ratio`);
    if (ratioCell) {
      ratioCell.textContent = `${roundData.total_tricks_asked}/${roundData.amount_of_cards}`;
    }

    // Update forbidden value
    const forbiddenCell = document.querySelector(`.game-table tbody tr:nth-child(${parseInt(index) + 1}) .forbidden-value`);
    if (forbiddenCell) {
      forbiddenCell.textContent = roundData.last_player_forbidden_value;
    }

    // Update points for all players
    document.querySelectorAll(`.game-table tbody tr:nth-child(${parseInt(index) + 1}) .points-cell`).forEach(cell => {
      const playerColumn = cell.closest('td').cellIndex;
      const player = gameState.players[playerColumn - 1]; // -1 because first column is card count
      const points = roundData.points[player];
      const pointsSpan = cell.querySelector('.points');
      if (pointsSpan) {
        pointsSpan.textContent = points || "-";
      }
    });
  });
}

function allPlayersAsked(round) {
  return Object.values(round.asked_tricks).every(v => v !== null);
}

function gameStateFromDOM() {
  return JSON.parse(document.querySelector('script').innerText.match(/var gameState = (.*);/)[1]);
}

async function fetchLeaderboard(gameId) {
  try {
    console.log('Fetching leaderboard for game:', gameId);
    const response = await fetch(`/api/leaderboard?game_id=${gameId}`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const leaderboard = await response.json();
    console.log('Received leaderboard data:', leaderboard);

    const leaderboardBody = document.getElementById('leaderboard-body');
    if (!leaderboardBody) {
      console.error('Could not find leaderboard-body element');
      return;
    }
    
    leaderboardBody.innerHTML = '';

    if (Object.keys(leaderboard).length === 0) {
      console.log('Leaderboard is empty');
      const row = document.createElement('tr');
      const cell = document.createElement('td');
      cell.colSpan = 2;
      cell.textContent = 'No scores yet';
      row.appendChild(cell);
      leaderboardBody.appendChild(row);
      return;
    }

    // Sort leaderboard by points in descending order
    const sortedLeaderboard = Object.entries(leaderboard)
      .sort(([,a], [,b]) => b - a);

    sortedLeaderboard.forEach(([player, points], index) => {
      const row = document.createElement('tr');
      const playerCell = document.createElement('td');
      const pointsCell = document.createElement('td');

      playerCell.textContent = player;
      pointsCell.textContent = points;

      // Highlight the leader
      if (index === 0) {
        row.classList.add('leader');
      }

      row.appendChild(playerCell);
      row.appendChild(pointsCell);
      leaderboardBody.appendChild(row);
    });
  } catch (error) {
    console.error('Failed to fetch leaderboard:', error);
    const leaderboardBody = document.getElementById('leaderboard-body');
    if (leaderboardBody) {
      leaderboardBody.innerHTML = '<tr><td colspan="2">Error loading leaderboard</td></tr>';
    }
  }
}