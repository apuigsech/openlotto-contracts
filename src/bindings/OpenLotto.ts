import { Contract, ContractTransaction, TransactionResponse, ethers, Signer, Interface, Log } from "ethers";
import { LotteryItem, TicketItem, NewLottery } from "./models";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.abi.json"
import LotteryDatabaseArtifact from "../../out/LotteryDatabase.sol/LotteryDatabase.abi.json"
import TicketDatabaseArtifact from "../../out/TicketDatabase.sol/TicketDatabase.abi.json"

class OpenLotto {
    contract: Contract;

    lottery_db: Contract;
    ticket_db: Contract;

    private constructor(address: string, signer: Signer) {
        this.contract = new ethers.Contract(address, OpenLottoArtifact, signer);
        this.initContracts().catch(error => {
            throw new Error(`Failed to initialize contracts: ${error.message}`);
        });   
    }

    private async initContracts() {
        const lotteryDatabaseAddr = await this.contract.GetLotteryDatabaseAddr();
        this.lottery_db = new ethers.Contract(lotteryDatabaseAddr, LotteryDatabaseArtifact);
        const ticketDatabaseAddr = await this.contract.GetTicketDatabaseAddr();
        this.ticket_db = new ethers.Contract(ticketDatabaseAddr, TicketDatabaseArtifact);        
    }

    public static async new(address: string, signer: Signer): Promise<OpenLotto> {
        const openlotto = new OpenLotto(address, signer);
        await openlotto.initContracts();
        return new Proxy(openlotto, {
            get(target, p) {
                if (p in target) {
                    return target[p]
                } else {
                    console.log("Forward Not Implemented yet:", typeof p, target[p]);
                }
            }
        });
    }

    public NewEmptyLottery(): LotteryItem {
        return NewLottery.fromEmpty();
    }

    public CreatedItem(tx: any): Promise<number> {
        const iface = new Interface(LotteryDatabaseArtifact);
        const createdItemEventSignature = iface.getEvent("CreatedItem");
        return tx.wait().then(receipt => {
            const logs = receipt.logs?.filter(e => e.topics[0] === createdItemEventSignature);
            if (logs && logs.length > 0) {
                return logs[0].topic[1];
            } else {
                throw new Error("CreatedItem event not found");
            }
        }).catch(error => {
            throw error;
        });
    }

    public async CreateLotteryAndWait(lottery: LotteryItem): Promise<number> {
        try {
            const tx = await this.contract.CreateLottery(lottery);
            const receipt = await tx.wait();
            let ids = receipt.logs.map((log) => {
                let event = this.lottery_db.interface.parseLog(log);
                if (event.name == 'CreatedItem' && event.args[0] == 'Lottery') {
                    return Number(event.args[1]);
                }
            });
            return ids[0];
        } catch (error) {
            throw new Error(this.lottery_db.interface.getError(error.data).name);
        }
    }

    public async ReadLottery(id: number): Promise<LotteryItem> {
        try {
            const result = await this.contract.ReadLottery(id);
            return NewLottery.fromResult(result);
        } catch (error) {
            throw new Error(this.lottery_db.interface.getError(error.data).name);
        }
    }

    public async BuyTicket(ticket: TicketItem, value: number): Promise<ContractTransaction> {
        return this.contract.BuyTicket(ticket, { value: value });
    }

    public BuyTicketAndWait(ticket: TicketItem, value: number): Promise<number> {
        return this.BuyTicket(ticket, value).then(tx => {
            return this.CreatedItem(tx);
        }).catch(error => {
            throw error;
        });
    }

    public async ReadTicket(id: number): Promise<TicketItem> {
        return this.contract.ReadTicket(id);
    }

    public async TicketPrizes(id: number, round: number): Promise<number> {
        return this.contract.TicketPrizes(id, round);
    }

    public async WithdrawTicket(id: number, round: number): Promise<ContractTransaction> {
        return this.contract.WithdrawTicket(id, round);
    }
}

export {
    OpenLotto, LotteryItem, TicketItem
}