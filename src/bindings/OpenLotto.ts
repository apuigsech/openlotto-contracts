import { Contract, ContractTransaction, TransactionResponse, ethers, Signer, Interface } from "ethers";
import { LotteryItem, TicketItem, NewLottery } from "./models";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.abi.json"
import LotteryDatabaseArtifact from "../../out/LotteryDatabase.sol/LotteryDatabase.abi.json"
import TicketDatabaseArtifact from "../../out/TicketDatabase.sol/TicketDatabase.abi.json"

function enableNoSuchMethod(obj) {
    return new Proxy(obj, {
        get(target, p) {
            if (p in target) {
                return target[p];
            } else if (typeof target.__noSuchMethod__ == "function") {
                return function(...args) {
                    return target.__noSuchMethod__.call(target, p, args);
                };
            }
        }
    });
}

function NewOpenLotto(address: string, signer: Signer) {
    let openlotto = new OpenLotto(address, signer);
    return enableNoSuchMethod(openlotto);
}

class OpenLotto {
    contract: Contract;

    lottery_db: Contract;
    ticket_db: Contract;

    constructor(address: string, signer: Signer) {
        this.contract = new ethers.Contract(address, OpenLottoArtifact, signer);
        this.initContracts();   
    }

    async initContracts() {
        const lotteryDatabaseAddr = await this.contract.GetLotteryDatabaseAddr();
        this.lottery_db = new ethers.Contract(lotteryDatabaseAddr, LotteryDatabaseArtifact);
        const ticketDatabaseAddr = await this.contract.GetTicketDatabaseAddr();
        this.ticket_db = new ethers.Contract(ticketDatabaseAddr, TicketDatabaseArtifact);        
    }

    __noSuchMethod__(methodName: string, args: any[]) {
        if (typeof this.contract[methodName] === 'function') {
            return this.contract[methodName](...args);
        } else {
            throw new Error(`Method '${methodName}' not found on OpenLotto or Contract.`);
        }
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
        return this.contract.ReadLottery(id).then(result => {
            return NewLottery.fromResult(result);
        }).catch(error => {
            throw error;
        });
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
    OpenLotto, LotteryItem, TicketItem, NewOpenLotto
}