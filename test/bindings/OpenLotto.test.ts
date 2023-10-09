import { ethers, JsonRpcProvider, NonceManager } from "ethers";
import { OpenLotto, LotteryItem, TicketItem } from '../../src/bindings/OpenLotto.ts';

import {
  newFilledLottery, newFilledTicket, newTestJsonRpcProvider, newWallet, runForgeScript
} from './helpers.ts';

const provider = new JsonRpcProvider("http://localhost:8545");
const mnemonic = "test test test test test test test test test test test junk";

const LOTTERY_MANAGER_IDX = 1
const ALICE_IDX = 2
const BOB_IDX = 3

const openLottoAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';
const dummyOperator = '0x8464135c8F25Da09e49BC8782676a84730C318bC';

let main_provider;

beforeAll(async () => {
  main_provider = await newTestJsonRpcProvider(8545);
  await runForgeScript(main_provider, 'script/DeployOpenLottoWithSampleData.s.sol:DeployOpenLotto', '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80')
}, 30000);

afterAll(async () => {
  main_provider['subprocess'].kill();
});


describe("CreateLottery", () => {
  let provider;
  let openlotto_manager, openlotto_user_1;

  beforeAll(async () => {
    provider = await newTestJsonRpcProvider(undefined, main_provider._getConnection().url);
    openlotto_manager = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, LOTTERY_MANAGER_IDX));
    openlotto_user_1 = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, ALICE_IDX));
  });

  afterAll(async () => {
    provider['subprocess'].kill();
  });


  test("CreateLottery should throw Unautorized for non lotery_managers", async () => {
    let lottery = newFilledLottery(dummyOperator);
    expect(openlotto_user_1.CreateLotteryAndWait(lottery)).rejects.toThrow();
  })

  test("CreateLottery should throw InvalidName when Name is empty", async () => {
    let lottery = newFilledLottery(dummyOperator);
    lottery.Name = "";
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidName");
  })

  test("CreateLottery should throw InvalidRoundsConfiguration when Rounds is 0", async () => {
    let lottery = newFilledLottery(dummyOperator);
    lottery.Rounds = 0;
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidRoundsConfiguration");
  })

  test("CreateLottery should throw InvalidRoundsConfiguration when RoundBlocks is 0", async () => {
    let lottery = newFilledLottery(dummyOperator);
    lottery.RoundBlocks = 0;
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidRoundsConfiguration");
  })

  test("CreateLottery should throw InvalidDistributionPool when DistributionPoolShare sume more than 100", async () => {
    let lottery = newFilledLottery(dummyOperator);
    lottery.DistributionPoolShare[0] = BigInt('1000000000000000001');
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidDistributionPool");
  })

  test("CreateLottery should throw InvalidPrizePool when PrizePoolShare doesn't sume 100", async () => {
    let lottery = newFilledLottery(dummyOperator);
    lottery.PrizePoolShare[0] = BigInt('0');
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidPrizePool");
  })

  test("CreateLottery should throw InvalidOperator when Operator is invalid", async () => {
    let lottery = newFilledLottery(dummyOperator);
    lottery.Operator = '0x0000000000000000000000000000000000000000'
    expect(openlotto_manager.CreateLotteryAndWait(lottery)).rejects.toThrow("InvalidOperator");
  })

  test("CreateLottery should return incremental ids", async () => {
    let lottery = newFilledLottery(dummyOperator);

    let id = await openlotto_manager.CreateLotteryAndWait(lottery);
    let id_1 = await openlotto_manager.CreateLotteryAndWait(lottery);
    let id_2 = await openlotto_manager.CreateLotteryAndWait(lottery);
    let id_3 = await openlotto_manager.CreateLotteryAndWait(lottery);
    
    expect(id_1).toEqual(id + 1);
    expect(id_2).toEqual(id + 2);
    expect(id_3).toEqual(id + 3);
  }, 30000)
});


describe("ReadLottery", () => {
  let id_1, id_2, id_3;
  let provider;
  let openlotto_manager, openlotto_user_1;

  beforeAll(async () => {
    provider = await newTestJsonRpcProvider(undefined, main_provider._getConnection().url);
    openlotto_manager = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, LOTTERY_MANAGER_IDX));
    openlotto_user_1 = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, ALICE_IDX));

    let lottery = newFilledLottery(dummyOperator);
    lottery.Name = "dummy 1"
    id_1 = await openlotto_manager.CreateLotteryAndWait(lottery);
    lottery.Name = "dummy 2"
    id_2 = await openlotto_manager.CreateLotteryAndWait(lottery);
    lottery.Name = "dummy 3"
    id_3 = await openlotto_manager.CreateLotteryAndWait(lottery);
  }, 30000);

  afterAll(async () => {
    provider['subprocess'].kill();
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
  let provider;
  let openlotto_manager, openlotto_user_1;

  beforeAll(async () => {
    provider = await newTestJsonRpcProvider(undefined, main_provider._getConnection().url);
    openlotto_manager = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, LOTTERY_MANAGER_IDX));
    openlotto_user_1 = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, ALICE_IDX));
    
    let lottery = newFilledLottery(dummyOperator);
    lottery.InitBlock = BigInt(await provider.getBlockNumber());
    lottery.Rounds = 10;
    lottery.RoundBlocks = 100;
    lottery.BetPrice = BigInt('10000000000000000');
    lottery_id = await openlotto_manager.CreateLotteryAndWait(lottery);
  });

  afterAll(async () => {
    provider['subprocess'].kill();
  });

  test("BuyTicket should throw InvalidID when LotteryID doesn't exist", async () => {
    let ticket = newFilledTicket();
    ticket.LotteryID = 0;
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidID");
  })

  test("BuyTicket should throw InvalidRounds when LotteryRoundInit is 0", async () => {
    let ticket = newFilledTicket();
    ticket.LotteryID = lottery_id;
    ticket.LotteryRoundInit = BigInt('0');
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidRounds");
  })

  test("BuyTicket should throw InvalidRounds when LotteryRoundFini is not higher than LotteryRoundInit", async () => {
    let ticket = newFilledTicket();
    ticket.LotteryID = lottery_id;
    ticket.LotteryRoundInit = BigInt('5');
    ticket.LotteryRoundFini = BigInt('4');
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidRounds");
  })

  test("BuyTicket should throw InvalidTicketRounds when LotteryRoundFini higher than the num of rounds for the lottery (Rounds)", async () => {
    let ticket = newFilledTicket();
    ticket.LotteryID = lottery_id;
    ticket.LotteryRoundInit = BigInt('1');
    ticket.LotteryRoundFini = BigInt('11');
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'))).rejects.toThrow("InvalidTicketRounds");
  })

  test("BuyTicket should throw InsuficientFunds when not enough value (based in BetPrice) is provided", async () => {
    let ticket = newFilledTicket();
    ticket.LotteryID = lottery_id;
    await expect(() => openlotto_user_1.BuyTicketAndWait(ticket)).rejects.toThrow("InsuficientFunds");
  })

  test("BuyTicket should return incremental ids", async () => {
    let ticket = newFilledTicket();
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


describe("ReadTicket", () => {
  let lottery_id;
  let id_1, id_2, id_3;
  let provider;
  let openlotto_manager, openlotto_user_1;

  beforeAll(async () => {
    provider = await newTestJsonRpcProvider(undefined, main_provider._getConnection().url);
    openlotto_manager = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, LOTTERY_MANAGER_IDX));
    openlotto_user_1 = await OpenLotto.new(openLottoAddress, newWallet(provider, mnemonic, ALICE_IDX));

    let lottery = newFilledLottery(dummyOperator);
    lottery.InitBlock = BigInt(await provider.getBlockNumber());
    lottery.Rounds = 10;
    lottery.RoundBlocks = 100;
    lottery.BetPrice = BigInt('10000000000000000');
    lottery_id = await openlotto_manager.CreateLotteryAndWait(lottery);

    let ticket = newFilledTicket();
    ticket.LotteryID = lottery_id;

    ticket.LotteryRoundInit = BigInt('1');
    ticket.LotteryRoundFini = BigInt('1');
    id_1 = await openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'));
  
    ticket.LotteryRoundInit = BigInt('2');
    ticket.LotteryRoundFini = BigInt('2');
    id_2 = await openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'));

    ticket.LotteryRoundInit = BigInt('3');
    ticket.LotteryRoundFini = BigInt('3');
    id_3 = await openlotto_user_1.BuyTicketAndWait(ticket, BigInt('10000000000000000'));

  }, 30000);

  afterAll(async () => {
    provider['subprocess'].kill();
  });

  test("ReadTicket should throw InvalidID for an invalid id", async () => {
    await expect(() => openlotto_user_1.ReadTicket(999)).rejects.toThrow("InvalidID");
  })

  test("ReadTicket should return the TicketItem for a given id", async () => {
    let ticket_1 = await openlotto_user_1.ReadTicket(id_1);

    expect(ticket_1.LotteryRoundInit).toEqual(BigInt('1'));
    let ticket_2 = await openlotto_user_1.ReadTicket(id_2);
    expect(ticket_2.LotteryRoundInit).toEqual(BigInt('2'));
    let ticket_3 = await openlotto_user_1.ReadTicket(id_3);
    expect(ticket_3.LotteryRoundInit).toEqual(BigInt('3'));
  })
})