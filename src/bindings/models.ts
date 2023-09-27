interface LotteryItem {
    Name: string;
    InitBlock: bigint;
    Rounds: number;
    RoundBlocks: number;
    BetPrice: bigint;
    JackpotMin: bigint;
    DistributionPoolTo: [string, string, string, string, string];
    DistributionPoolShare: [bigint, bigint, bigint, bigint, bigint];
    PrizePoolShare: [
        bigint, bigint, bigint, bigint, bigint,
        bigint, bigint, bigint, bigint, bigint,
        bigint, bigint, bigint, bigint, bigint,
        bigint, bigint, bigint, bigint, bigint
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
    LotteryRoundInit: bigint;
    LotteryRoundFini: bigint;
    NumBets: number;
    Attributes: string;
}

class NewLotteryFactory {
    public fromEmpty(): LotteryItem {
        let lottery: LotteryItem = {
            Name: '',
            InitBlock: BigInt('0'),
            Rounds: 0,
            RoundBlocks: 0,
            BetPrice: BigInt('0'),
            JackpotMin: BigInt('0'),
            DistributionPoolTo: [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000'
            ],
    
            DistributionPoolShare: [
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0')
            ],
            PrizePoolShare: [
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0'),
                BigInt('0')
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

    public fromResult(result): LotteryItem {
        let lottery = this.fromEmpty();
    
        lottery.Name = result[0];
        lottery.InitBlock = result[1];
        lottery.Rounds = result[2];
        lottery.RoundBlocks = result[3];
        lottery.BetPrice = result[4];
        lottery.JackpotMin = result[5];

        for (let i = 0 ; i < result[6].length ; i++) {
            lottery.DistributionPoolTo[i] = result[6][i];
        }

        for (let i = 0 ; i < result[7].length ; i++) {
            lottery.DistributionPoolShare[i] = result[7][i];
        }

        for (let i = 0 ; i < result[8].length ; i++) {
            lottery.PrizePoolShare[i] = result[8][i];
        }

        for (let i = 0 ; i < result[9].length ; i++) {
            lottery.PrizePoolAttributes[i] = result[9][i];
        }

        lottery.Operator = result[10];
        lottery.Attributes = result[11];

        return lottery;
    }
}

let NewLottery = new NewLotteryFactory();

export { LotteryItem, TicketItem, NewLottery }