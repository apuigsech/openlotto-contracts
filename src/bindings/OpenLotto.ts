import { Contract, ContractTransaction, TransactionResponse, ethers, Signer, Interface, Log, ErrorFragment } from "ethers";
import { LotteryItem, TicketItem, NewLottery, NewTicket } from "./models";

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

    public static NewEmptyLottery(): LotteryItem {
        return NewLottery.fromEmpty();
    }

    public static NewEmptyTicket(): TicketItem {
        return NewTicket.fromEmpty();
    }

    private getError(e): ErrorFragment {
        const interfaces = [
            this.contract.interface,
            this.lottery_db.interface,
            this.ticket_db.interface
        ]
        for (let i = 0 ; i < interfaces.length ; i++) {
            let error = interfaces[i].getError(e);
            if (error != null) {
                return error;
            }
        }
        return null;
    }

    public async CreateLotteryAndWait(lottery: LotteryItem): Promise<number> {
        try {
            const tx = await this.contract.CreateLottery(lottery);
            const receipt = await tx.wait();
            let ids = receipt.logs.map((log) => {
                let event = this.lottery_db.interface.parseLog(log);
                if (event && event.name == 'CreatedItem' && event.args[0] == 'Lottery') {
                    return Number(event.args[1]);
                }
            });
            return ids[0];
        } catch (e) {
            let error =  this.getError(e.data);
            if (error != null) {
                throw new Error(error.name);
            } else {
                throw new Error(e.data);
            }
        }
    }

    public async ReadLottery(id: number): Promise<LotteryItem> {
        try {
            const result = await this.contract.ReadLottery(id);
            return NewLottery.fromResult(result);
        } catch (e) {
            let error =  this.getError(e.data);
            if (error != null) {
                throw new Error(error.name);
            } else {
                throw new Error(e.data);
            }
        }
    }

    public async BuyTicket(ticket: TicketItem, value: number): Promise<ContractTransaction> {
        return this.contract.BuyTicket(ticket, { value: value });
    }

    public async BuyTicketAndWait(ticket: TicketItem, value: number): Promise<number> {
        try {
            const tx = await this.contract.BuyTicket(ticket, { value: value });
            const receipt = await tx.wait();
            let ids = receipt.logs.map((log) => {
                let event = this.ticket_db.interface.parseLog(log);
                if (event && event.name == 'CreatedItem' && event.args[0] == 'Ticket') {
                    return Number(event.args[1]);
                }
            }); 
            return ids[0];       
        } catch (e) {
            let error =  this.getError(e.data);
            if (error != null) {
                throw new Error(error.name);
            } else {
                throw new Error(e.data);
            }   
        }
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