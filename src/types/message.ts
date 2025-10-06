export interface Message {
  _id: string;
  senderId: number;
  receiverId: number;
  text?: string;
  image?: string;
  createdAt: string;
  updatedAt: string;
}
