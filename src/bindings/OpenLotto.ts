import { Contract, ContractTransaction, ethers, Signer, ErrorFragment, NonceManager } from "ethers";
import { LotteryItem, TicketItem, NewLottery, NewTicket } from "./models";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.abi.json"
import LotteryDatabaseArtifact from "../../out/LotteryDatabase.sol/LotteryDatabase.abi.json"
import TicketDatabaseArtifact from "../../out/TicketDatabase.sol/TicketDatabase.abi.json"

class OpenLotto {
    contract: Contract;

    lottery_db: Contract;
    ticket_db: Contract;

    private constructor(address: string, signer: Signer) {
        try {
            this.contract = new ethers.Contract(address, OpenLottoArtifact, signer);
            this.initContracts();
        } catch (error) {
            throw error;
        }
    }

    private async initContracts() {
        try {
            const lotteryDatabaseAddr = await this.contract.GetLotteryDatabaseAddr();
            this.lottery_db = new ethers.Contract(lotteryDatabaseAddr, LotteryDatabaseArtifact);
            const ticketDatabaseAddr = await this.contract.GetTicketDatabaseAddr();
            this.ticket_db = new ethers.Contract(ticketDatabaseAddr, TicketDatabaseArtifact);
        } catch (error) {
            throw error;
        }     
    }

    public static async new(address: string, signer: Signer): Promise<OpenLotto> {
        const openlotto = new OpenLotto(address, signer);
        await openlotto.initContracts();
        return new Proxy(openlotto, {
            get(target, p) {
                if (p in target) {
                    return target[p]
                } else {
                    // console.log("Forward Not Implemented yet:", typeof p, target[p]);
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

    private resolveError(e): ErrorFragment {
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

    public CreateLotteryAndWait(lottery: LotteryItem): Promise<number> {
        return this.contract.CreateLottery(lottery).then((tx) => {
            return tx.wait().then((receipt) => {
                let ids = receipt.logs.map((log) => {
                    let event = this.lottery_db.interface.parseLog(log);
                    if (event && event.name == 'CreatedItem' && event.args[0] == 'Lottery') {
                        return Number(event.args[1]);
                    }
                });
                return ids[0];
            }).catch((error) =>{
                throw new Error('Error in wait: ' + error);
            });
        }).catch((error) =>{
            if (error.info.error.code == 3) {
                throw new Error(this.resolveError(error.data).name);
            } else {
                throw new Error(error.info.error.message);
            }
        });
    }

    public ReadLottery(id: number): Promise<LotteryItem> {
        return this.contract.ReadLottery(id).then((result) => {
            return NewLottery.fromResult(result);
        }).catch((error) =>{
            throw new Error(this.resolveError(error.data).name);
        });
    }

    public BuyTicket(ticket: TicketItem, value: number): Promise<ContractTransaction> {
        return this.contract.BuyTicket(ticket, { value: value });
    }

    public BuyTicketAndWait(ticket: TicketItem, value: bigint): Promise<number> {
        return this.contract.BuyTicket(ticket, { value: value }).then((tx) => {
            return tx.wait().then((receipt) => {
                let ids = receipt.logs.map((log) => {
                    let event = this.ticket_db.interface.parseLog(log);
                    if (event && event.name == 'CreatedItem' && event.args[0] == 'Ticket') {
                        return Number(event.args[1]);
                    }
                }); 
                return ids[0]; 
            }).catch((error) =>{
                throw new Error('Error in wait: ' + error);
            });
        }).catch((error) =>{
            if (error.info.error.code == 3) {
                throw new Error(this.resolveError(error.data).name);
            } else {
                throw new Error(error.info.error.message);
            }
        });
    }

    public async ReadTicket(id: number): Promise<TicketItem> {
        return this.contract.ReadTicket(id).then((result) => {
            return NewTicket.fromResult(result);
        }).catch((error) =>{
            throw new Error(this.resolveError(error.data).name);
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
    OpenLotto, LotteryItem, TicketItem
}