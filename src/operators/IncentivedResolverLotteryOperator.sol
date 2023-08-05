// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

abstract contract IncentivedResolverLotteryOperatorInterface is LotteryOperatorInterface {
    uint32 private UnresolvedBets;
    mapping (uint32 => mapping (uint32 => uint32)) private UnresolvedBetsPerLotteryRound;


    function CreateTicket(uint32 id, TicketModel.TicketItem memory ticket)  
        override public
        onlyRole(OPERATOR_CONTROLER_ROLE)
    {
        for (uint32 round = ticket.LotteryRoundInit ; round <= ticket.LotteryRoundFini ; round++) { 
            UnresolvedBetsPerLotteryRound[ticket.LotteryID][round] += ticket.NumBets;
            UnresolvedBets += ticket.NumBets;
        }

        super.CreateTicket(id, ticket); 
    }

    function ResolveRound(uint32 lottery_id, LotteryModel.LotteryItem memory lottery, uint32 round, uint256 seed)
        override public
        onlyRole(OPERATOR_CONTROLER_ROLE)
    {
        uint256 amount = UnresolvedBetsPerLotteryRound[lottery_id][round] * (address(this).balance / UnresolvedBets);

        UnresolvedBets -= UnresolvedBetsPerLotteryRound[lottery_id][round];
        UnresolvedBetsPerLotteryRound[lottery_id][round] = 0;

        super.ResolveRound(lottery_id, lottery, round, seed);
    
        if (amount > 0) payable(tx.origin).transfer(amount);  
    }

    receive() external payable {}
}