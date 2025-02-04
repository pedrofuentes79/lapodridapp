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
          updateGameState(input, action, player, value, gameId);
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
    updateGameState(input, action, player, value, gameId);
    fetchLeaderboard(gameId);
}

function sendGameState(gameState, gameId) {
  console.log('Sending game id', gameId);
  return fetch('/api/update_game_state', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ game_state: gameState, game_id: gameId })
  })
  .then(response => response.json())
  .catch(error => {
    console.error('Error:', error);
    throw error;
  });
}

function updateGameState(inputElement, action, player, value, gameId) {
  const gameState = gameStateFromDOM();
  
  // Get the round number from the input element's data attribute
  const roundNumber = parseInt(inputElement.dataset.round, 10);
  const round = gameState.rounds[roundNumber];

  if (action === 'askForTricks') {
    round.asked_tricks[player] = parseInt(value, 10);
  } else if (action === 'registerTricks') {
    round.tricks_made[player] = parseInt(value, 10);
  }

  updateTricksInDOM(gameState);
  
  return sendGameState(gameState, gameId);
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
  const scriptContent = document.querySelector('script').innerText;
  console.log('Script content:', scriptContent);

  const match = scriptContent.match(/var gameState = (.*);/);
  if (!match || match.length < 2) {
    throw new Error('Game state not found in script tag');
  }

  return JSON.parse(match[1]);
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

async function refreshGameData(gameId) {
  try {
    // Fetch the updated game HTML from the server
    const response = await fetch(`/game/${gameId}`);
    const html = await response.text();
    
    // Create a temporary container to parse the HTML
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');
    
    // Update the game table
    const newGameTable = doc.querySelector('.game-table');
    const currentGameTable = document.querySelector('.game-table');
    if (newGameTable && currentGameTable) {
      currentGameTable.innerHTML = newGameTable.innerHTML;
    }
    
    // Update the game state in the script tag
    const newGameState = doc.querySelector('script');
    if (newGameState) {
      document.querySelector('script').innerHTML = newGameState.innerHTML;
    }
    
    // Fetch and update leaderboard
    await fetchLeaderboard(gameId);
    
    // Reattach event listeners to new elements
    attachEventListeners();
    
  } catch (error) {
    console.error('Failed to refresh game data:', error);
  }
}

function attachEventListeners() {
  const editableElements = document.querySelectorAll(".editable");
  
  editableElements.forEach((element) => {
    // Remove existing listeners to prevent duplicates
    element.replaceWith(element.cloneNode(true));
    const newElement = document.querySelector(`[data-player="${element.dataset.player}"][data-round="${element.dataset.round}"][data-action="${element.dataset.action}"]`);
    
    newElement.addEventListener("dblclick", (event) => {
      const span = event.target;
      const player = span.dataset.player;
      const round = span.dataset.round;
      const action = span.dataset.action;
      const value = span.innerText;
      const gameId = span.dataset.gameid;
      
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
      
      const handleChange = async (event) => {
        if (isHandled) return;
        isHandled = true;
        
        const value = input.value;
        span.innerText = value === "" ? "-" : value;
        span.style.display = "inline";
        
        input.removeEventListener("blur", handleChange);
        input.removeEventListener("keypress", handleKeyPress);
        input.remove();
        
        // Update game state and refresh all data
        await updateGameState(input, action, player, value, gameId);
        await refreshGameData(gameId);
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
}

async function handleInputChange(event) {
    const input = event.target;
    const player = input.dataset.player;
    const gameId = input.dataset.gameid;
    const action = input.dataset.action;
    const value = input.value;
    const span = input.nextSibling;

    span.innerText = value === "" ? "-" : value;
    span.style.display = "inline";
    input.remove();

    await updateGameState(input, action, player, value, gameId);
    await refreshGameData(gameId);
}

// Add initial event listener attachment when the page loads
document.addEventListener("DOMContentLoaded", () => {
    attachEventListeners();
    
    // Initial leaderboard load
    const gameId = document.querySelector('.points-cell').getAttribute('game-id');
    fetchLeaderboard(gameId);
});