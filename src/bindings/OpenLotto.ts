import { Contract, ContractTransaction, ethers, Signer, ErrorFragment, NonceManager } from "ethers";
import { Lottery, Ticket } from "./models";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.abi.json"

const OpenLottoOnChain = {
    'sepolia': {
        'version': {
            'latest': {
                'address': '0x21FBd49FfdDc52AB3e088813E48B2C3BB06A4528',
                'operators': {
                    'None': '0x0000000000000000000000000000000000000000',
                    'Dummy': '0x32049dCEB926f5Dbda4e4215ce603e8252C69B21',
                }
            }
        }
    }
}

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
        return this.contract.ReadLottery(id).then(async (result) => {
            let lottery = Lottery.fromResult(result).withID(id).withOpenLotto(this) as Lottery;
            return await lottery.withAutoSync() as Lottery;
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
            return Ticket.fromResult(result).withID(id).withOpenLotto(this).withAutoSync() as Ticket;
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
    OpenLotto, OpenLottoOnChain, Lottery, Ticket
}