--[[
	"Get A Job, Baby!" is a game written by Eetu Rantanen for Ludum Dare 45

	Copyright (C) 2019 - Spyric Entertainment

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

local dialogue = {

	nurse = {
		"Congratulations! It's a..."
	},

	father = {
		birth = {
			start = {
				"It's a disappointment, that is! By that age, I had already delivered papers for a year.",
				"It's a disgrace, that it is!  I never had the luxury of just lying around.",
				"It's too old to be lying around and not contributing to society, that is!"
			},
			newround = {
				"Don't let me down like your older sibling did!",
				"I hope this one makes me proud",
				"Get a job already!"
			},
		},
		gameover = {
			start = {
				"Let's see how you did...",
				"Are you in charge of your own company by now?",
				"How many billions are you worth?"
			},
			finish = {
				"When I was your age, I had already twice that.",
				"I was expecting better from my offspring.",
				"Are you trying to mock me?"
			},
		},
	},

	jobs = {
		shepherd = {
			"Do you like working with animals?",
			"Can you look after my sheep while I'm away?",
			"Do you enjoy working outdoors?"
		},
		miner = {
			"You look like the appropriate height.",
			"Are you interested in gold and gems?",
			"You look like a man for physical labour!"
		},
		fisher = {
			"Wanna go fishin'?",
			"If you want money, there's nothin' better than fishin'!",
			"You look a bit young... still, wanna go fish?"
		},
		gamble = {
			"Do you want high risk, high reward?",
			"It's not gambling if you know what you are doing.",
			"Double or nothing!"
		},
		trader = {
			"The economy is booming, Baby!",
			"Can you press two buttons?",
			"Ever seen the movie \"The Wolf of Wall Street\"?",
			"Wanna play with stocks?"
		},

		-- traps
		socialworker = {
			"Are you all by yourself?",
			"Do you need help?",
			"Did your father just abandon you?"
		},
		newfamily = {
			"Oh my god! Are you all alone?!",
			"Do you want to come home with me and my husband?",
			"Do you need a new loving family?"
		},
	},

}

return dialogue
