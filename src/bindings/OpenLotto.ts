import { Contract, ContractTransaction, ethers, Signer } from "ethers";

import OpenLottoArtifact from "../../out/OpenLotto.sol/OpenLotto.json"
import DatabaseArtifact from "../../out/Database.sol/Database.json"

interface LotteryItem {
    Name: string;
    InitBlock: ethers.BigNumber;
    Rounds: number;
    RoundBlocks: number;
    BetPrice: ethers.BigNumber;
    JackpotMin: ethers.BigNumber;
    DistributionPoolTo: [string, string, string, string, string];
    DistributionPoolShare: [ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber];
    PrizePoolShare: [
        ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber,
        ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber,
        ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber,
        ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber, ethers.BigNumber
    ];
    PrizePoolAttributes: [
        string, string, string, string, string,
        string, string, string, string, string,
        string, string, string, string, string,
        string, string, string, string, string
    ];
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

    public NewEmptyLottery(): LotteryItem {
        let lottery: LotteryItem = {
            Name: '',
            InitBlock: ethers.BigNumber.from('0'),
            Rounds: 0,
            RoundBlocks: 0,
            BetPrice: ethers.BigNumber.from('0'),
            JackpotMin: ethers.BigNumber.from('0'),
            DistributionPoolTo: [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000'
            ],

            DistributionPoolShare: [
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0')
            ],
            PrizePoolShare: [
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0'),
                ethers.BigNumber.from('0')
            ],
            PrizePoolAttributes: [
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000',
                '0x0000000000000000'              
            ],
            Operator: '0x0000000000000000000000000000000000000000',
            Attributes: '0x00000000000000000000000000000000'
        };
        return lottery;
    }


    public CreatedItem(tx: ContractTransaction): Promise<number> {
        const iface = new ethers.utils.Interface(DatabaseArtifact["abi"]);
        const createdItemEventSignature = iface.getEventTopic("CreatedItem");
        return tx.wait().then(receipt => {
            const events = receipt.events?.filter(e => e.topics[0] === createdItemEventSignature).map(e => iface.parseLog(e));
            if (events && events.length > 0) {
                return events[0].args.id;
            } else {
                throw new Error("CreatedItem event not found");
            }
        }).catch(error => {
            console.error(error);
            throw error;
        });
    }

    public async CreateLottery(lottery: LotteryItem): Promise<ContractTransaction> {
        return this.functions.CreateLottery(lottery);
    }

    public CreateLotteryAndWait(lottery: LotteryItem): Promise<number> {
        return this.CreateLottery(lottery).then(tx => {
            return this.CreatedItem(tx);
        }).catch(error => {
            console.error(error);
            throw error;
        });
    }

    public async ReadLottery(id: number): Promise<LotteryItem> {
        return this.functions.ReadLottery(id).then(res => {
            const [Name, InitBlock, Rounds, RoundBlocks, BetPrice, JackpotMin, DistributionPoolTo, DistributionPoolShare, PrizePoolShare, PrizePoolAttributes, Operator, Attributes] = res[0];
            return {Name, InitBlock, Rounds, RoundBlocks, BetPrice, JackpotMin, DistributionPoolTo, DistributionPoolShare, PrizePoolShare, PrizePoolAttributes, Operator, Attributes};
        }).catch(error => {
            console.error(error);
            throw error;
        });
    }

    public async BuyTicket(ticket: TicketItem, value: number): Promise<ContractTransaction> {
        return this.functions.BuyTicket(ticket, { value: value });
    }

    public BuyTicketAndWait(ticket: TicketItem, value: number): Promise<number> {
        return this.BuyTicket(ticket, value).then(tx => {
            return this.CreatedItem(tx);
        }).catch(error => {
            throw error;
        });
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
    OpenLotto, LotteryItem
}