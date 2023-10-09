import { ethers, JsonRpcProvider, NonceManager } from "ethers";
import { OpenLotto, LotteryItem, TicketItem } from '../../src/bindings/OpenLotto.ts';

const provider = new JsonRpcProvider("http://localhost:8545");
const mnemonic = "test test test test test test test test test test test junk";

const LOTTERY_MANAGER_IDX = 1
const ALICE_IDX = 2
const BOB_IDX = 3

const openLottoAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';
const dummyOperator = '0x8464135c8F25Da09e49BC8782676a84730C318bC';

function Wallet(provider: JsonRpcProvider, mnemonic: string, index: number) { 
  const path = `m/44'/60'/0'/0/${index}`;
  const signer = ethers.HDNodeWallet.fromMnemonic(ethers.Mnemonic.fromPhrase(mnemonic), path);
  return signer.connect(provider);
}

let openlotto_manager, openlotto_user_1, openlotto_user_2;

beforeAll(async () => {
  openlotto_manager = await OpenLotto.new(openLottoAddress, Wallet(provider, mnemonic, LOTTERY_MANAGER_IDX));
  openlotto_user_1 = await OpenLotto.new(openLottoAddress, Wallet(provider, mnemonic, ALICE_IDX));
  openlotto_user_2 = await OpenLotto.new(openLottoAddress, Wallet(provider, mnemonic, BOB_IDX));
});


function NewFilledLottery(): LotteryItem {
  let lottery = OpenLotto.NewEmptyLottery();
  lottery.Name = 'dummy';
  lottery.InitBlock = BigInt('10');
  lottery.Rounds = 10;
  lottery.RoundBlocks = 100;
  lottery.BetPrice = BigInt('10000000000000000');
  lottery.PrizePoolShare[0] = BigInt('1000000000000000000');
  lottery.Operator = dummyOperator;
  return lottery;
}

function NewFilledTicket(): TicketItem {
  let ticket = OpenLotto.NewEmptyTicket();
  ticket.LotteryID = 1;
  ticket.LotteryRoundInit = BigInt('1');
  ticket.LotteryRoundFini = BigInt('1');
  ticket.NumBets = 1;
  return ticket;
}

describe("CreateLottery", () => {
  beforeAll(async () => {
  });

  beforeEach(async () => {
  });

  test("CreateLottery should throw Unautorized for non lotery_managers", async () => {
    let lottery = NewFilledLottery();
    expect(openlotto_user_1.CreateLotteryAndWait(lottery)).rejects.toThrow();
  })

  test("CreateLottery should throw InvalidName when Name is empty", async () => {
    let lottery = NewFilledLottery();
    lottery.Name = "";
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidName");
  })

  test("CreateLottery should throw InvalidRoundsConfiguration when Rounds is 0", async () => {
    let lottery = NewFilledLottery();
    lottery.Rounds = 0;
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidRoundsConfiguration");
  })

  test("CreateLottery should throw InvalidRoundsConfiguration when RoundBlocks is 0", async () => {
    let lottery = NewFilledLottery();
    lottery.RoundBlocks = 0;
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidRoundsConfiguration");
  })

  test("CreateLottery should throw InvalidDistributionPool when DistributionPoolShare sume more than 100", async () => {
    let lottery = NewFilledLottery();
    lottery.DistributionPoolShare[0] = BigInt('1000000000000000001');
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidDistributionPool");
  })

  test("CreateLottery should throw InvalidPrizePool when PrizePoolShare doesn't sume 100", async () => {
    let lottery = NewFilledLottery();
    lottery.PrizePoolShare[0] = BigInt('0');
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidPrizePool");
  })

  test("CreateLottery should throw InvalidOperator when Operator is invalid", async () => {
    let lottery = NewFilledLottery();
    lottery.Operator = '0x0000000000000000000000000000000000000000'
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidOperator");
  })

  test("CreateLottery should return incremental ids", async () => {
    let lottery = NewFilledLottery();

    let id = await openlotto_manager.CreateLotteryAndWait(lottery);
    let id_1 = await openlotto_manager.CreateLotteryAndWait(lottery);
    let id_2 = await openlotto_manager.CreateLotteryAndWait(lottery);
    let id_3 = await openlotto_manager.CreateLotteryAndWait(lottery);
    
    expect(id_1).toEqual(id + 1);
    expect(id_2).toEqual(id + 2);
    expect(id_3).toEqual(id + 3);
  }, 100000)
});


describe("ReadLottery", () => {
  let id_1, id_2, id_3;

  beforeAll(async () => {
    let lottery = NewFilledLottery();
    lottery.Name = "dummy 1"
    id_1 = await openlotto_manager.CreateLotteryAndWait(lottery);
    lottery.Name = "dummy 2"
    id_2 = await openlotto_manager.CreateLotteryAndWait(lottery);
    lottery.Name = "dummy 3"
    id_3 = await openlotto_manager.CreateLotteryAndWait(lottery);
  }, 30000);

  beforeEach(async () => {

  });

  test("ReadLottery should throw InvalidID for an invalid id", async () => {
    await expect(() => openlotto_user_1.ReadLottery(999)).rejects.toThrow("InvalidID");
  })

  test("ReadLottery should return the LotteryItem for a given id", async () => {
    let lottery_1 = await openlotto_user_1.ReadLottery(id_1);
    expect(lottery_1.Name).toEqual("dummy 1");
    let lottery_2 = await openlotto_user_1.ReadLottery(id_2);
    expect(lottery_2.Name).toEqual("dummy 2");
    let lottery_3 = await openlotto_user_1.ReadLottery(id_3);
    expect(lottery_3.Name).toEqual("dummy 3");
  })
})


describe("BuyTicket", () => {
  let lottery_id;

  beforeAll(async () => {
    let lottery = NewFilledLottery();
    lottery.InitBlock = BigInt(await provider.getBlockNumber());
    lottery.Rounds = 10;
    lottery.RoundBlocks = 100;
    lottery.BetPrice = BigInt('10000000000000000');
    lottery_id = await openlotto_manager.CreateLotteryAndWait(lottery);
  }, 30000);

  beforeEach(async () => {

  });

  test("BuyTicket should throw InvalidID when LotteryID doesn't exist", async () => {
    let ticket = NewFilledTicket();
    ticket.LotteryID = 0;
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidID");
  })

  test("BuyTicket should throw InvalidRounds when LotteryRoundInit is 0", async () => {
    let ticket = NewFilledTicket();
    ticket.LotteryID = lottery_id;
    ticket.LotteryRoundInit = BigInt('0');
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidRounds");
  })

  test("BuyTicket should throw InvalidRounds when LotteryRoundFini is not higher than LotteryRoundInit", async () => {
    let ticket = NewFilledTicket();
    ticket.LotteryID = lottery_id;
    ticket.LotteryRoundInit = BigInt('5');
    ticket.LotteryRoundFini = BigInt('4');
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidRounds");
  })

  test("BuyTicket should throw InvalidTicketRounds when LotteryRoundFini higher than the num of rounds for the lottery (Rounds)", async () => {
    let ticket = NewFilledTicket();
    ticket.LotteryID = lottery_id;
    ticket.LotteryRoundInit = BigInt('1');
    ticket.LotteryRoundFini = BigInt('11');
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidTicketRounds");
  })

  test("BuyTicket should throw InsuficientFunds when not enough value (based in BetPrice) is provided", async () => {
    let ticket = NewFilledTicket();
    ticket.LotteryID = lottery_id;
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket)).rejects.toThrow("InsuficientFunds");
  })

  test("BuyTicket should return incremental ids", async () => {
    let ticket = NewFilledTicket();
    ticket.LotteryID = lottery_id;

    let id = await openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'));
    let id_1 = await openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'));
    let id_2 = await openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'));
    let id_3 = await openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'));

    expect(id_1).toEqual(id + 1);
    expect(id_2).toEqual(id + 2);
    expect(id_3).toEqual(id + 3);
  }, 30000)

})