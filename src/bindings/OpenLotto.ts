import { Contract, ContractTransaction, ethers, Signer } from "ethers";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.json"
import DatabaseArtifact from "../../out/Database.sol/Database.json"

interface LotteryItem {
    Name: string;
    InitBlock: number;
    Rounds: number;
    RoundBlocks: number;
    BetPrice: number;
    JackpotMin: number;
    DistributionPoolTo: string[];
    DistributionPoolShare: number[];
    PrizePoolShare: number[];
    PrizePoolAttributes: string[];
    Operator: string;
    Attributes: string;
}

interface TicketItem {
    LotteryID: number;
    LotteryRoundInit: number;
    LotteryRoundFini: number;
    NumBets: number;
}

class OpenLotto extends Contract {
    constructor(address: string, signer: Signer) {
        super(address, OpenLottoArtifact["abi"], signer);
    }

    public async CreatedItem(tx: ContractTransaction): Promise<number> {
        try {
            const iface = new ethers.utils.Interface(DatabaseArtifact["abi"]);
            const receipt = await tx.wait();
            const createdItemEventSignature = iface.getEventTopic("CreatedItem");
            const events = receipt.events?.filter((e) => e.topics[0] === createdItemEventSignature).map((e) => iface.parseLog(e));
            if (events && events.length > 0) {
                return events[0].args.id;
            } else {
                throw new Error("CreatedItem event not found");
            }
        } catch (error) {
            console.error(error);
            throw error;
        }
    }

    public async CreateLottery(lottery: LotteryItem): Promise<ContractTransaction> {
        return this.functions.CreateLottery(lottery);
    }

    public async CreateLotteryAndWait(lottery: LotteryItem): Promise<number> {
        try {
            const tx = await this.CreateLottery(lottery);
            return await this.CreatedItem(tx);
        } catch (error) {
            throw error;
        }
    }

    public async ReadLottery(id: number): Promise<LotteryItem> {
        return this.functions.ReadLottery(id);
    }

    public async BuyTicket(ticket: TicketItem, value: number): Promise<ContractTransaction> {
        return this.functions.BuyTicket(ticket, { value: value });
    }

    public async BuyTicketAndWait(ticket: TicketItem, value: number): Promise<number> {
        try {
            const tx = await this.BuyTicket(ticket, value);
            return await this.CreatedItem(tx);
        } catch (error) {
            throw error;
        }
    }

    public async ReadTicket(id: number): Promise<TicketItem> {
        return this.functions.ReadTicket(id);
    }

    public async TicketPrizes(id: number, round: number): Promise<number> {
        return this.functions.TicketPrizes(id, round);
    }

    public async WithdrawTicket(id: number, round: number): Promise<ContractTransaction> {
        return this.functions.WithdrawTicket(id, round);
    }
}

export {
    OpenLotto
}