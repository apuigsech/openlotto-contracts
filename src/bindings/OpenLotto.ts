import { Contract, ContractTransaction, ethers, Signer, ErrorFragment, NonceManager } from "ethers";
import { Lottery, Ticket } from "./models";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.abi.json"

class OpenLotto {
    contract: Contract;

    constructor(address: string, signer: Signer) {
        try {
            this.contract = new ethers.Contract(address, OpenLottoArtifact, signer);
        } catch (error) {
            throw error;
        }
    }

    private makeError(error) {
        if (error.code == "CALL_EXCEPTION") {
            error = this.contract.interface.makeError(error.data, error);
        }
        return error;
    }

    public static NewEmptyLottery(): Lottery {
        return Lottery.fromEmpty();
    }

    public static NewEmptyTicket(): Ticket {
        return Ticket.fromEmpty();
    }

    public CreateLotteryAndWait(lottery: Lottery): Promise<number> {
        return this.contract.CreateLottery(lottery).then((tx) => {
            return tx.wait().then((receipt) => {
                let ids = receipt.logs.map((log) => {
                    let event = this.contract.interface.parseLog(log);
                    if (event && event.name == 'CreatedItem' && event.args[0] == 'Lottery') {
                        return Number(event.args[1]);
                    }
                });
                return ids[0];
            }).catch((error) =>{
                throw error;
            });
        }).catch((error) =>{
            error = this.makeError(error);
            throw error;
        });
    }

    public ReadLottery(id: number): Promise<Lottery> {
        return this.contract.ReadLottery(id).then((result) => {
            return Lottery.fromResult(result);
        }).catch((error) =>{
            error = this.makeError(error);
            throw error;
        });
    }

    public BuyTicket(ticket: Ticket, value: number): Promise<ContractTransaction> {
        return this.contract.BuyTicket(ticket, { value: value });
    }

    public BuyTicketAndWait(ticket: Ticket, value: bigint): Promise<number> {
        return this.contract.BuyTicket(ticket, { value: value }).then((tx) => {
            return tx.wait().then((receipt) => {
                let ids = receipt.logs.map((log) => {
                    let event = this.contract.interface.parseLog(log);
                    if (event && event.name == 'CreatedItem' && event.args[0] == 'Ticket') {
                        return Number(event.args[1]);
                    }
                }); 
                return ids[0]; 
            }).catch((error) =>{
                throw error;
            });
        }).catch((error) =>{
            error = this.makeError(error);
            throw error;
        });
    }

    public async ReadTicket(id: number): Promise<Ticket> {
        return this.contract.ReadTicket(id).then((result) => {
            return Ticket.fromResult(result);
        }).catch((error) =>{
            error = this.makeError(error);
            throw error;
        });
    }

    public async TicketPrizes(id: number, round: number): Promise<number> {
        return this.contract.TicketPrizes(id, round);
    }

    public async WithdrawTicket(id: number, round: number): Promise<ContractTransaction> {
        return this.contract.WithdrawTicket(id, round);
    }
}

export {
    OpenLotto, Lottery, Ticket
}