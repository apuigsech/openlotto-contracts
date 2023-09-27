import { Contract, ContractTransaction, TransactionResponse, ethers, Signer, Interface } from "ethers";
import { LotteryItem, TicketItem, NewLottery } from "./models";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.abi.json"
import DatabaseArtifact from "../../out/Database.sol/Database.abi.json"

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

    constructor(address: string, signer: Signer) {
        this.contract = new ethers.Contract(address, OpenLottoArtifact, signer);
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
        const iface = new Interface(DatabaseArtifact);
        const createdItemEventSignature = iface.getEvent("CreatedItem");;
        return tx.wait().then(receipt => {
            console.log(">>>", receipt.logs);
            console.log(createdItemEventSignature);
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

    // public CreateLottery(lottery: LotteryItem): any {
    //     return this.contract.CreateLottery(lottery);
    // }

    public CreateLotteryAndWait(lottery: LotteryItem): Promise<number> {
        return this.contract.CreateLottery(lottery).then(tx => {
            return this.CreatedItem(tx);
        }).catch(error => {
            throw error;
        });
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