const GAME_STATE_SELECTOR = '#game-state';


document.addEventListener("DOMContentLoaded", () => {
    const editableElements = document.querySelectorAll(".editable"); 

    // DBLCLICK ON SPAN TURNS INTO INPUT
    editableElements.forEach((element) => {
      element.addEventListener("dblclick", (event) => {
        const span = event.target;
        const player = span.dataset.player;
        const roundNumber = span.dataset.round;
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
        input.dataset.round = roundNumber;
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

function sendGameState(gameState, gameId) {
  console.log('Sending game id', gameId);
  return fetch(`/api/games/${gameId}/update_game_state`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ game_state: gameState, id: gameId })
  })
  .then(response => response.json())
  .catch(error => {
    console.error('Error:', error);
    throw error;
  });
}

function updateGameState(inputElement, action, player, value, gameId) {
  const gameState = gameStateFromDOM();
  console.log('Game state:', gameState);
  
  // EDITS GAME STATE WITH VALUES FROM DOM
  const roundNumber = parseInt(inputElement.dataset.round, 10);
  const round = gameState.rounds[roundNumber];

  if (action === 'askForTricks') {
    round.asked_tricks[player] = parseInt(value, 10);
  } else if (action === 'registerTricks') {
    round.tricks_made[player] = parseInt(value, 10);
  }

  updateTricksInDOM(gameState);
  
  return sendGameState(gameState, gameId)
    .then(response => {
      console.log('Game state updated successfully');
      return response;
    })
    .catch(error => {
      console.error('Error updating game state:', error);
      throw error;
    });
}

function updateTricksInDOM(gameState) {
  const roundNumber = gameState.current_round_number;
  const round = gameState.rounds[roundNumber];
  
  // Update the gameState in the script tag
  document.querySelector(GAME_STATE_SELECTOR).innerText = `var gameState = ${JSON.stringify(gameState)};`;

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
  const scriptContent = document.querySelector(GAME_STATE_SELECTOR).innerText;

  const match = scriptContent.match(/var gameState = (.*);/);
  if (!match || match.length < 2) {
    throw new Error('Game state not found in script tag');
  }

  // Decode HTML entities
  const decodedGameState = match[1]
    .replace(/&quot;/g, '"')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&apos;/g, "'");

  console.log('Game state:', decodedGameState);
  return JSON.parse(decodedGameState);
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